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
  # Now that jellyfin comes from our own arr-packages fork (tracks upstream
  # release tags directly), we're back to nixpkgs' native services.jellyfin
  # instead of the official container image.
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

  # The module can now generate encoding.xml from services.jellyfin.transcoding.*,
  # but our own file carries tuning (tonemapping detail, QSV device, deinterlace
  # method, segment retention...) that isn't exposed as options. mkAfter runs
  # this once the module's own preStart (which only writes if missing) is done,
  # so our unconditional install always wins.
  systemd.services.jellyfin.preStart = lib.mkAfter ''
    test -f "${config.services.jellyfin.configDir}/system.xml" || install -m 640 ${systemXml} "${config.services.jellyfin.configDir}/system.xml"
    install -m 640 ${encodingXml} "${config.services.jellyfin.configDir}/encoding.xml"
  '';

  # nixpkgs' services.jellyfin module hardcodes UMask=0077, so anything
  # Jellyfin writes under the setgid (2775) media library dirs -- .nfo saves,
  # .trickplay tiles -- gets created group-inaccessible (0700) despite
  # inheriting group "media", causing Permission denied on the next
  # read/write (own or another *arr service's). Match the UMask=0002 used
  # for servicesWithMediaAccess in ../default.nix so new content stays
  # group-writable.
  systemd.services.jellyfin.serviceConfig.UMask = lib.mkForce "0002";
}
