# Dedicated shadPS4 launcher for Bloodborne (mod manager, save backups,
# trophy viewing). Not in nixpkgs — wrapped from upstream's prebuilt Linux
# AppImage. https://github.com/rainmakerv3/BB_Launcher
{
  lib,
  pkgs,
  ...
}: let
  pname = "bb-launcher";
  version = "16.10";

  src = pkgs.fetchurl {
    # "Downloader" build bundles QtWebEngine so non-premium mod downloads
    # work from within the launcher (the other Linux build can't: no native
    # web API for QtWebView on Linux, per upstream README).
    url = "https://github.com/rainmakerv3/BB_Launcher/releases/download/Release${version}/BB_Launcher-qt-Downloader.AppImage";
    hash = "sha256-iWCiDbqSk+0LeJRH7OnvfYtmTCwT6PjX3B2yDyHG/mI=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {inherit pname version src;};

  bb-launcher = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/BBLauncher.desktop $out/share/applications/${pname}.desktop
      install -m 444 -D ${appimageContents}/BBIcon.png $out/share/icons/hicolor/512x512/apps/${pname}.png
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=BB_Launcher' 'Exec=${pname}' \
        --replace-fail 'Icon=BBIcon' 'Icon=${pname}'
    '';

    meta = {
      description = "Dedicated shadPS4 launcher for Bloodborne (mod manager, save backups, trophies)";
      homepage = "https://github.com/rainmakerv3/BB_Launcher";
      license = lib.licenses.gpl2Only;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  };
in {
  home.packages = [bb-launcher];
}
