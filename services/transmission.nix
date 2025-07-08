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

    # This is the ONLY script hook available in the pia-vpn module.
    # We will perform all actions (IP update and Port update) here.
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      # The port is passed as the first argument to this script.
      PORT="$1"
      
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook
      
      # Give the interface a moment to be fully ready
      sleep 2

      # Get the IP address of the wg0 interface
      VPN_IP=$(${pkgs.iproute2}/bin/ip -4 addr show wg0 | ${pkgs.gnugrep}/bin/grep -oP '(?<=inet\s)\d+(\.\d+){3}')

      # Path to Transmission's real settings file
      SETTINGS_FILE="/var/lib/transmission/.config/transmission-daemon/settings.json"

      if [ -n "$VPN_IP" ]; then
        echo "PIA Hook: Found VPN IP $VPN_IP. Updating bind address." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook
        # Use jq to safely update the JSON file in-place
        ${pkgs.jq}/bin/jq --arg ip "$VPN_IP" '."bind-address-ipv4" = $ip' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
      else
        echo "PIA Hook: Could not find IP for wg0. Bind address not updated." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook
      fi

      # Update the peer port using transmission-remote
      ${pkgs.transmission_4}/bin/transmission-remote --peerport "$PORT" || true
      
      # Tell the running transmission service to reload its config to apply the new IP
      ${pkgs.systemd}/bin/systemctl reload transmission.service
    '';

    # Ensure the static IP setting is null, so our script can manage it.
    services.transmission.settings."bind-address-ipv4" = mkForce null;

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