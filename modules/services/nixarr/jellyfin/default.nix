{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.services.jellyfin;
  systemXml = ./system.xml;
  encodingXml = ./encoding.xml;
in {
  systemd.services.jellyfin.path = [pkgs.chromaprint];
  users.users.jellyfin = {
    isSystemUser = true;
    group = lib.mkForce "jellyfin";
    extraGroups = [
      "users"
      "media"
      "render"
      "video"
      "input"
    ];
  };

  services.jellyfin = {
    enable = true;
    dataDir = "/data/media/.state/nixarr/jellyfin/data";
    configDir = "/data/media/.state/nixarr/jellyfin/config";
    cacheDir = "/data/media/.state/nixarr/jellyfin/cache";
    logDir = "/data/media/.state/nixarr/jellyfin/log";
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
    forceEncodingConfig = true;
  };
  systemd.services.jellyfin.preStart = lib.mkAfter ''
    install -m 640 ${systemXml} "${cfg.configDir}/system.xml"
    install -m 640 ${encodingXml} "${cfg.configDir}/encoding.xml"
  '';
}
