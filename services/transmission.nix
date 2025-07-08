{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;
in
{
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the VPN";
  };

  config = mkIf (cfg.enable && cfg.vpn.enable) {
    # Ensure Transmission only starts after the VPN is fully connected.
    services.transmission.wantedBy = [ "pia-vpn.service" ];
    services.transmission.after = [ "pia-vpn.service" ];

    # Bind the Transmission service to the VPN's network interface IP address.
    # This is the critical part to prevent traffic from leaking.
    # Your VPN interface is named 'wg0'.
    systemd.services.transmission.serviceConfig = {
      BindToDevice = "wg0";
    };

    # Configure PIA port forwarding for optimal torrenting.
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      PORT="$1"
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook

      # Wait a moment to ensure the transmission daemon is ready.
      sleep 5

      # We just tell transmission-remote to set the new port.
      # No RPC authentication is needed since the script runs locally.
      ${pkgs.transmission}/bin/transmission-remote --peerport "$PORT" || true
    '';

    # Add the transmission user to the necessary groups.
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];

    # Ensure the port forwarding script has access to necessary packages.
    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission
      pkgs.systemd # for systemd-cat
    ];
  };
} 