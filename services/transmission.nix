{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;
  updateTransmissionScript = pkgs.writeShellApplication {
    name = "update-transmission-ip";
    runtimeInputs = with pkgs; [ iproute2 jq coreutils systemd ];
    
    # FIX 2: Use the absolute path to your script file.
    text = builtins.readFile /etc/nixos/scripts/update-transmission-ip.sh;
  };
in
{
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";
  };

  config = mkIf (cfg.enable && cfg.vpn.enable) {
    
    # FIX 1: Use the correct option name 'connection.script'.
    services.pia-vpn.connection.script = "${updateTransmissionScript}/bin/update-transmission-ip";

    services.transmission.settings."bind-address-ipv4" = mkForce null;
    
    systemd.services.transmission = {
      after = [ "pia-vpn.service" ];
      wantedBy = [ "pia-vpn.service" ];
      serviceConfig.BindToDevice = "wg0";
    };
    
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];
  };
}