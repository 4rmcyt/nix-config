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