{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;
  updateTransmissionScript = pkgs.writeShellApplication {
    name = "update-transmission-ip";
    runtimeInputs = with pkgs; [ iproute2 jq coreutils systemd ];
    text = builtins.readFile ./scripts/update-transmission-ip.sh;
  };
in
{
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";
  };

  config = mkIf (cfg.enable && cfg.vpn.enable) {
    services.pia-vpn.upScript = "${updateTransmissionScript}/bin/update-transmission-ip";
    services.transmission.settings."bind-address-ipv4" = mkForce null;
    systemd.services.transmission = {
      after = [ "pia-vpn.service" ];
      wantedBy = [ "pia-vpn.service" ];
      serviceConfig.BindToDevice = "wg0";
    };
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];
  };
}