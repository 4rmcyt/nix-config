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
  # chromaprint (fpcalc) required by Intro Skipper for audio fingerprinting
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

    # Hardware acceleration — enables DeviceAllow + preStart encoding.xml handling.
    # We manage encoding.xml ourselves below, so forceEncodingConfig is disabled.
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
    forceEncodingConfig = false;
  };

  # Only write config files if they don't already exist (first boot / fresh state).
  # lib.mkAfter ensures this runs after nixpkgs' own preStart for encoding.xml.
  systemd.services.jellyfin.preStart = lib.mkAfter ''
    install -m 640 -n ${systemXml} "${cfg.configDir}/system.xml" || true
    install -m 640 -n ${encodingXml} "${cfg.configDir}/encoding.xml" || true
  '';
}
