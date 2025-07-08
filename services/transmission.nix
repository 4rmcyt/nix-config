{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;
in
{
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";
  };

  config = mkIf (cfg.enable && cfg.vpn.enable) {

    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}

      # --- KEY CHANGE ---
      # The port isn't passed as an argument ($1). We must read it from the
      # file provided by the pia-vpn service. This fixes the empty port issue.
      if [ ! -f /run/pia-vpn/port ]; then
        echo "PIA Hook: Port file not found. Aborting." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook
        exit 1
      fi
      PORT=$(cat /run/pia-vpn/port)
      
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook
      
      sleep 2

      VPN_IP=$(${pkgs.iproute2}/bin/ip -4 addr show wg0 | ${pkgs.gnugrep}/bin/grep -oP '(?<=inet\s)\d+(\.\d+){3}')
      SETTINGS_FILE="/var/lib/transmission/.config/transmission-daemon/settings.json"

      if [ -z "$VPN_IP" ]; then
        echo "PIA Hook: Could not find IP for wg0. Aborting update." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook
        exit 1
      fi

      echo "PIA Hook: Found VPN IP $VPN_IP. Updating settings file." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook

      # Use one jq command to update both the IP and the Port in the settings file.
      ${pkgs.jq}/bin/jq \
        --arg ip "$VPN_IP" \
        --argjson port "$PORT" \
        '."bind-address-ipv4" = $ip | ."peer-port" = $port' \
        "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
      
      # Using restart is more forceful and reliable than reload.
      ${pkgs.systemd}/bin/systemctl restart transmission.service
    '';

    # Ensure the static IP and port are managed by the script, not the config.
    services.transmission.settings = {
      "bind-address-ipv4" = mkForce null;
      "peer-port" = 51413; # A valid default port is required.
    };

    systemd.services.transmission = {
      after = [ "pia-vpn.service" ];
      wantedBy = [ "pia-vpn.service" ];
      serviceConfig.BindToDevice = "wg0";
    };

    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];
  };
}