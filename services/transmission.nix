{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;
in
{
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";
    settings = { #Override default settings
      rpc-bind-address = "0.0.0.0"; #Bind to own IP
      rpc-whitelist = "127.0.0.1,100.60.0.1/24,192.168.1.0/24"; 
    };
  };

  config = mkIf (cfg.enable && cfg.vpn.enable) {

    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      PORT="$1"
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook

      # Since the script runs locally, we don't need RPC authentication.
      # We just tell transmission-remote to set the new port.
      transmission-remote --peerport "$PORT" || true
    '';

    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];
    systemd.services.transmission-daemon.bindsTo = [ "pia-vpn.service" ];
    systemd.services.transmission-daemon.after = [ "pia-vpn.service" ];
    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd # for systemd-cat
    ];
  };
}