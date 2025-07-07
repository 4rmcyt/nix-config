{ config, pkgs, lib, ... }:

let
  # A helper script to update the Deluge port when PIA assigns a new one.
  # This script is called by the main pia-wg script via the PORTFORWARD_HOOK.
  update-deluge-port-script = pkgs.writeShellScript "update-deluge-port.sh" ''
    #!/bin/sh
    PORT="$1"
    # This check ensures we only run the command if a valid port is given.
    if [ -n "$PORT" ] && [ "$PORT" -gt 0 ]; then
      echo "PIA Hook: Updating Deluge to listen on port $PORT"
      # Use the 'deluge' user to run the deluge-console command.
      ${pkgs.sudo}/bin/sudo -u deluge ${pkgs.deluge}/bin/deluge-console \
        "config --set listen_ports ($PORT,$PORT); config --set random_port false"
    fi
  '';

  # Package for the pia-wg script.
  # This uses the official package and wraps it with a declarative configuration.
  pia-wg-package = pkgs.unstable.pia-wg.overrideAttrs (oldAttrs: {
    # The overrideAttrs allows us to modify the package without rebuilding it from scratch.
    postInstall = ''
      # Create a declarative config file that the pia-wg script will automatically use.
      # It looks for a file named 'pia-config.sh' in the same directory as the main script.
      cat > $out/bin/pia-config.sh <<EOF
      # Get credentials securely from sops
      PIA_USERNAME="$(cat ${config.sops.secrets.pia_username.path})"
      PIA_PASSWORD="$(cat ${config.sops.secrets.pia_password.path})"

      # Set your desired location
      LOC="ca_ontario"

      # Name for the WireGuard network interface
      PIA_INTERFACE="pia"

      # Enable port forwarding and set the hook to our script
      PORTFORWARD="yes"
      PORTFORWARD_HOOK="${update-deluge-port-script}"
      EOF
    '';
  });

in
{
  # == User and System Setup ==
  # Creates the 'deluge' user and group for running the services.
  users.users.deluge = {
    isSystemUser = true;
    group = "deluge";
    home = "/var/lib/deluge";
  };
  users.groups.deluge = {};

  # == Secrets Management ==
  # Ensures the 'deluge' user has permission to read the PIA credentials.
  sops.secrets.pia_username.owner = config.users.users.deluge.name;
  sops.secrets.pia_password.owner = config.users.users.deluge.name;

  # == Deluge Configuration Service ==
  # This service runs ONLY ONCE to create initial, sane default settings for Deluge.
  systemd.services.deluge-init-config = {
    description = "Initialize Deluge configuration files";
    wantedBy = [ "multi-user.target" ];
    # This service must run before the main Deluge daemon.
    before = [ "deluged.service" ];

    # This condition checks if the 'auth' file exists. If it does, the service does nothing.
    # This makes the service idempotent (safe to run multiple times).
    conditionPathExists = "!/var/lib/deluge/.config/deluge/auth";

    serviceConfig = {
      Type = "oneshot";
      User = "deluge"; # Run all commands as the 'deluge' user.
      Group = "deluge";
    };

    # The script creates the necessary config files and sets permissions.
    script = ''
      CONFIG_DIR="/var/lib/deluge/.config/deluge"
      mkdir -p "$CONFIG_DIR"
      # Set up authentication and allow remote connections
      echo "localclient:placeholder:10" > "$CONFIG_DIR/auth"
      echo '{
        "allow_remote": true,
        "download_location": "/var/lib/deluge/downloads"
      }' > "$CONFIG_DIR/core.conf"
    '';
  };

  # == VPN Service ==
  # This service establishes and maintains the WireGuard connection to PIA.
  systemd.services.pia-connection = {
    description = "Manages the dynamic PIA WireGuard connection";
    wantedBy = [ "multi-user.target" ];
    # It must start after the network is online.
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple"; # Use 'simple' for long-running processes.
      # The user needs access to SOPS secrets and networking capabilities.
      User = "deluge";
      # The command to run. The '&' backgrounds it, and 'wait' keeps the service running.
      ExecStart = "${pia-wg-package}/bin/pia-wg & wait $!";
      # When the service stops, tear down the WireGuard interface.
      ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down pia";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  # == Deluge Daemon Service ==
  # This is the main Deluge process.
  systemd.services.deluged = {
    description = "Deluge BitTorrent Daemon (VPN-only)";
    wantedBy = [ "multi-user.target" ];
    # Must start after both the PIA connection is up and the initial config is done.
    after = [ "pia-connection.service" "deluge-init-config.service" ];
    wants = [ "pia-connection.service" ];

    serviceConfig = {
      User = "deluge";
      Group = "deluge";
      # This critical option forces all of Deluge's network traffic through the 'pia' interface.
      BindToInterface = "pia";
      ExecStart = ''
        ${pkgs.deluge}/bin/deluged --do-not-daemonize -c /var/lib/deluge/.config/deluge
      '';
      Restart = "always";
    };
  };

  # == Deluge Web UI Service ==
  # This provides the web interface for managing Deluge.
  systemd.services.deluge-web = {
    description = "Deluge BitTorrent Web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "deluged.service" ];
    wants = [ "deluged.service" ];

    serviceConfig = {
      Type = "simple";
      User = "deluge";
      Group = "deluge";
      ExecStart = ''
        ${pkgs.deluge}/bin/deluge-web --do-not-daemonize -c /var/lib/deluge/.config/deluge
      '';
      Restart = "always";
    };
  };

  # == Firewall ==
  # Allows access to the Deluge Web UI from other computers on your network.
  networking.firewall.allowedTCPPorts = [ 8112 ];
}