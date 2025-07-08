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
      PORT="$1"
      
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook
      
      sleep 2

      VPN_IP=$(${pkgs.iproute2}/bin/ip -4 addr show wg0 | ${pkgs.gnugrep}/bin/grep -oP '(?<=inet\s)\d+(\.\d+){3}')
      SETTINGS_FILE="/var/lib/transmission/.config/transmission-daemon/settings.json"

      if [ -z "$VPN_IP" ]; then
        echo "PIA Hook: Could not find IP for wg0. Aborting update." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook
        exit 1
      fi

      echo "PIA Hook: Found VPN IP $VPN_IP. Updating settings file." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook

      # --- KEY CHANGE ---
      # Use one jq command to update both the IP and the Port in the settings file.
      # We use --argjson for the port so it's treated as a number, not a string.
      ${pkgs.jq}/bin/jq \
        --arg ip "$VPN_IP" \
        --argjson port "$PORT" \
        '."bind-address-ipv4" = $ip | ."peer-port" = $port' \
        "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
      
      # Now, reload the service to apply *both* changes from the file at once.
      # The 'transmission-remote' command is no longer needed.
      ${pkgs.systemd}/bin/systemctl reload transmission.service
    '';

    # Ensure the static IP and port are managed by the script, not the config.
    services.transmission.settings = {
      "bind-address-ipv4" = mkForce null;
      "peer-port" = mkForce null;
    };

    # Systemd settings for service ordering and as a defense-in-depth kill switch.
    systemd.services.transmission = {
      after = [ "pia-vpn.service" ];
      wantedBy = [ "pia-vpn.service" ];
      serviceConfig.BindToDevice = "wg0";
    };

    # Ensure the transmission user is in the correct group.
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];
  };
}