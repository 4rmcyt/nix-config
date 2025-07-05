{ config, pkgs, lib, ... }:

let
  # 1. Port Forwarding Hook Script
  update-deluge-port-script = pkgs.writeShellScript "update-deluge-port.sh" ''
    #!/bin/sh
    PORT="$1"
    echo "Port Forwarding Hook: Received port $PORT. Updating Deluge..."
    ${pkgs.sudo}/bin/sudo -u deluge ${pkgs.deluge}/bin/deluge-console \
      "config --set listen_ports ($PORT,$PORT); config --set random_port false"
  '';

  # 2. Declarative PIA Configuration
  pia-config-file = pkgs.writeText "pia-config.sh" ''
    PIA_USERNAME="$(cat ${config.sops.secrets.pia_username.path})"
    PIA_PASSWORD="$(cat ${config.sops.secrets.pia_password.path})"
    LOC="ca_ontario"
    PIA_INTERFACE="pia"
    PORTFORWARD="yes"
    PORTFORWARD_HOOK="${update-deluge-port-script}"
  '';

  # 3. Package the Dynamic pia-wg.sh Script (using writeShellApplication for robustness)
  pia-wg-package = pkgs.writeShellApplication {
    name = "pia-wg-wrapper";
    
    # This automatically creates the PATH for the script with all its dependencies.
    runtimeInputs = [
      pkgs.bash
      pkgs.wireguard-tools
      pkgs.curl
      pkgs.jq
      pkgs.iproute2
      pkgs.qrencode
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.which
    ];

    # This is the content of our wrapper script.
    text = ''
      # Set the environment variable that pia-wg.sh needs to find its config.
      export PIA_CONFIG=${pia-config-file}
      # Execute the real script, passing along any arguments.
      exec ${../scripts/pia-wg.sh} "$@"
    '';
  };

in
{
  # == User and System Setup ==
  users.users.deluge = {
    isSystemUser = true;
    group = "deluge";
    uid = 1001;
    home = "/var/lib/deluge";
    createHome = true;
    extraGroups = [ "users" ];
  };
  users.groups.deluge = { gid = 1001; };
  sops.secrets.pia_username.owner = "deluge";
  sops.secrets.pia_password.owner = "deluge";
  systemd.tmpfiles.rules = [
    "d /var/lib/deluge/downloads 0755 deluge deluge - -"
  ];

  # == Deluge Configuration Service ==
  systemd.services.deluge-init-config = {
    description = "Initialize Deluge configuration files";
    wantedBy = [ "multi-user.target" ];
    before = [ "deluged.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/test ! -f /var/lib/deluge/.config/deluge/auth";
    };
    script = ''
      CONFIG_DIR="/var/lib/deluge/.config/deluge"
      AUTH_FILE="$CONFIG_DIR/auth"
      echo "Initializing Deluge config for the first time..."
      mkdir -p "$CONFIG_DIR"
      echo "localclient:placeholder:10" > "$AUTH_FILE"
      echo "deluge::10" >> "$AUTH_FILE"
      echo '{
        "allow_remote": true,
        "download_location": "/var/lib/deluge/downloads"
      }' > "$CONFIG_DIR/core.conf"
      chown -R deluge:deluge /var/lib/deluge
      chmod 700 "$CONFIG_DIR"
      chmod 600 "$CONFIG_DIR"/*
    '';
  };

  # == VPN and Deluge Services ==
  systemd.services.pia-connection = {
    description = "Manages the dynamic PIA WireGuard connection";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ config.sops.secrets.pia_username.path config.sops.secrets.pia_password.path ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pia-wg-package}/bin/pia-wg-wrapper"; # Note the wrapper name
      ExecStop = "${pkgs.iproute2}/bin/ip link del dev pia";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  systemd.services.deluged = {
    description = "Deluge BitTorrent Daemon (VPN-only)";
    after = [ "pia-connection.service" "deluge-init-config.service" ];
    wants = [ "pia-connection.service" "deluge-init-config.service" ];
    serviceConfig = {
      User = "deluge";
      Group = "deluge";
      ExecStart = ''
        ${pkgs.deluge}/bin/deluged --do-not-daemonize \
          -c /var/lib/deluge/.config/deluge \
          -l /var/lib/deluge/daemon.log -L info
      '';
      BindToInterface = "pia";
      Restart = "always";
    };
  };

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
        ${pkgs.deluge}/bin/deluge-web --do-not-daemonize \
          -c /var/lib/deluge/.config/deluge \
          -l /var/lib/deluge/web.log -L info
      '';
      Restart = "always";
    };
  };

  # == Firewall ==
  networking.firewall.allowedTCPPorts = [ 8112 ]; # Deluge Web UI
}