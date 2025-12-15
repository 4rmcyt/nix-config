{
  config,
  lib,
  pkgs,
  ...
}:
# Workaround for nixarr upnp typo bug
# The nixarr module has a typo: it references cfg.openUpdPorts instead of cfg.openUdpPorts
# This module fixes it by directly setting the systemd service script
{
  config = lib.mkIf config.util-nixarr.upnp.enable {
    systemd.services.upnpc = lib.mkForce {
      description = "Open ports using UPnP";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.miniupnpc pkgs.coreutils];

      script = ''
        set +e  # Don't exit on errors, continue with remaining ports
        ${lib.strings.concatMapStrings (x: "upnpc -r ${builtins.toString x} UDP || true\nsleep 4\n") config.util-nixarr.upnp.openUdpPorts}
        ${lib.strings.concatMapStrings (x: "upnpc -r ${builtins.toString x} TCP || true\nsleep 4\n") config.util-nixarr.upnp.openTcpPorts}
        exit 0  # Always exit successfully
      '';

      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}
