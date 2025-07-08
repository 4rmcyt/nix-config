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
     services.pia-vpn.portForward = {
    enable = true;
    script = ''
      ${pkgs.transmission_4}/bin/transmission-remote --port $port || true
    '';
  };

   
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];


    systemd.services.transmission.bindsTo = [ "pia-vpn.service" ];
    systemd.services.transmission.after = [ "pia-vpn.service" ];


    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd # for systemd-cat
    ];
  };
}