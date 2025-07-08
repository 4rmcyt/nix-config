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
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];
    systemd.services.transmission-daemon.bindsTo = [ "pia-vpn.service" ];
    systemd.services.transmission-daemon.after = [ "pia-vpn.service" ];


    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd # for systemd-cat
    ];
  };
}