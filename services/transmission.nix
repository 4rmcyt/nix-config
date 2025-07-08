# /etc/nixos/transmission.nix
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

    # 1. CONFIGURE SYSTEMD
    # This is where all service management and network binding happens.
    #--------------------------------------------------------------------
    systemd.services.transmission = {
      # Make transmission start after and be wanted by the VPN service.
      after = [ "pia-vpn.service" ];
      wantedBy = [ "pia-vpn.service" ];

      # This is the network kill-switch. It forces all traffic for this
      # service through the 'wg0' (WireGuard) network interface.
      serviceConfig.BindToDevice = "wg0";
    };


    # 2. CONFIGURE PIA PORT FORWARDING
    #--------------------------------------------------------------------
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      PORT="$1"
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook
      # Give the daemon a moment to be ready for commands
      sleep 5
      # Update the port using the full package path
      ${pkgs.transmission_4}/bin/transmission-remote --peerport "$PORT" || true
    '';

    # Ensure the port forward script has access to necessary packages
    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd # for systemd-cat
    ];


    # 3. CONFIGURE USER PERMISSIONS
    #--------------------------------------------------------------------
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];

  };
}