{
  lib,
  pkgs,
  config,
  ...
}: let
  systemXml = ./system.xml;
  encodingXml = pkgs.replaceVars ./encoding.xml {
    fallbackFontPath = "${pkgs.noto-fonts}/share/fonts/noto";
  };
in {
  systemd.services.jellyfin.path = [pkgs.chromaprint pkgs.jellyfin-ffmpeg];

  # jellyfin-ffmpeg (libass) needs a fontconfig-visible font with Hebrew
  # glyphs to burn in / render Hebrew subtitles; without one they show as
  # tofu boxes or drop out entirely.
  fonts.packages = [pkgs.noto-fonts];

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
  };

  # Our encoding.xml carries tuning not exposed as options; mkAfter runs after the
  # module's own preStart (which only writes if missing), so this always wins.
  systemd.services.jellyfin.preStart = lib.mkAfter ''
    test -f "${config.services.jellyfin.configDir}/system.xml" || install -m 640 ${systemXml} "${config.services.jellyfin.configDir}/system.xml"
    install -m 640 ${encodingXml} "${config.services.jellyfin.configDir}/encoding.xml"
  '';

  # nixpkgs' module hardcodes UMask=0077, making Jellyfin's writes under the setgid
  # media dirs group-inaccessible; match servicesWithMediaAccess's UMask=0002 instead.
  systemd.services.jellyfin.serviceConfig.UMask = lib.mkForce "0002";
}
