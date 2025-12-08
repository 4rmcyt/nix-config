{ config, lib, pkgs, ... }:

# Workaround for nixarr upnp typo bug
# The nixarr module has a typo: it references cfg.openUpdPorts instead of cfg.openUdpPorts
# This module fixes it by directly setting the systemd service script

{
  config = lib.mkIf config.util-nixarr.upnp.enable {
    systemd.services.upnpc = lib.mkForce {
      description = "Open ports using UPnP";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.miniupnpc ];

      script =
        (lib.strings.concatMapStrings (x: "upnpc -r ${builtins.toString x} UDP\n") config.util-nixarr.upnp.openUdpPorts)
        + (lib.strings.concatMapStrings (x: "upnpc -r ${builtins.toString x} TCP\n") config.util-nixarr.upnp.openTcpPorts);

      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}
