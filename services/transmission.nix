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

    # This is the single, correct script that handles everything.
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}

      # ... (the top part of the script is the same) ...
      
      echo "PIA Hook: Found Port $PORT and IP $VPN_IP. Updating Transmission." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook
      
      SETTINGS_FILE="/var/lib/transmission/.config/transmission-daemon/settings.json"

      # Update both IP and Port in the settings file at once.
      ${pkgs.jq}/bin/jq \
        --arg ip "$VPN_IP" \
        --argjson port "$PORT" \
        '."bind-address-ipv4" = $ip | ."peer-port" = $port' \
        "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
      
      # --- KEY CHANGE ---
      # Wait a brief moment before restarting to ensure file writes are complete
      # and other services have settled.
      sleep 2

      # Restart the service to apply both settings from the file.
      ${pkgs.systemd}/bin/systemctl restart transmission.service
    '';

    # The script now manages the IP, so force the static setting to null.
    services.transmission.settings."bind-address-ipv4" = mkForce null;

    # Keep the essential systemd settings for service order and the network kill-switch.
    systemd.services.transmission = {
      after = [ "pia-vpn.service" ];
      wantedBy = [ "pia-vpn.service" ];
      serviceConfig.BindToDevice = "wg0";
    };

    # User group permissions.
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];
  };
}