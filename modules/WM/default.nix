{
  lib,
  config,
  osConfig,
  ...
}:
with lib; {
  # =================================================================
  # Automatic Window Manager Module Loading
  # =================================================================
  # This module automatically imports the correct WM configuration
  # based on the system's my.desktop.windowManager setting

  imports = let
    wm = osConfig.my.desktop.windowManager or "none";
    wmModules = {
      hyprland = ./hyprland;
      niri = ./niri;
    };
  in
    [
      ../GUI/zed
    ]
    ++ optional (wm != "none" && hasAttr wm wmModules) wmModules.${wm};

  # =================================================================
  # XDG Configuration
  # =================================================================
  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;

      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
      videos = "${config.home.homeDirectory}/Videos";
    };

    # XDG MIME Applications
    mimeApps = {
      enable = true;
      defaultApplications = {
        # File Manager
        "inode/directory" = "org.gnome.Nautilus.desktop";

        # Text Editor
        "text/plain" = "dev.zed.Zed.desktop";
        "text/x-script" = "dev.zed.Zed.desktop";
        "application/x-shellscript" = "dev.zed.Zed.desktop";

        # Browser
        "text/html" = "chromium-browser.desktop";
        "x-scheme-handler/http" = "chromium-browser.desktop";
        "x-scheme-handler/https" = "chromium-browser.desktop";
        "x-scheme-handler/about" = "chromium-browser.desktop";
        "x-scheme-handler/unknown" = "chromium-browser.desktop";

        # PDF
        "application/pdf" = "org.pwmt.zathura.desktop";

        # Images
        "image/png" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/jpg" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/webp" = "imv.desktop";

        # Video
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/webm" = "mpv.desktop";

        # Audio
        "audio/mpeg" = "mpv.desktop";
        "audio/flac" = "mpv.desktop";
        "audio/x-wav" = "mpv.desktop";
      };
    };
  };
}
