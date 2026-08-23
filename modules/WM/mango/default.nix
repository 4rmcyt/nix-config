{pkgs, ...}: {
  imports = [
    ./binds.nix
    ./startup.nix
    ./windowrules.nix
    ../gtk.nix
  ];

  home.sessionVariables = {
    # Wayland/Ozone
    ANKI_WAYLAND = "1";
    MOZ_ENABLE_WAYLAND = "1";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "mango";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "mango";

    # Qt
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland;xcb";

    # Quickshell (noctalia-shell) icon theme override — bypasses Qt/GTK theme
    # autodetection, which noctalia-shell's Quickshell.iconPath() does not
    # reliably follow. See https://quickshell.org/docs/master/types/Quickshell/Quickshell
    QS_ICON_THEME = "Papirus-Dark";
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
    qt5ctSettings.Appearance.icon_theme = "Papirus-Dark";
    qt6ctSettings.Appearance.icon_theme = "Papirus-Dark";

    # See modules/WM/hyprland/default.nix for the full explanation — no
    # [Fonts] section meant qt5ct/qt6ct handed Qt apps a null QFont,
    # breaking QPainter for custom-drawn widgets (file dialogs, etc.).
    # Values must carry literal quote chars — QSettings parses an
    # unquoted comma-bearing value as a QStringList, and
    # QVariant::toString() on a multi-element list returns "", which is
    # what was still breaking QFont::fromString() despite this section
    # existing.
    qt5ctSettings.Fonts.general = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
    qt5ctSettings.Fonts.fixed = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
    qt6ctSettings.Fonts.general = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
    qt6ctSettings.Fonts.fixed = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
  };

  home.packages = with pkgs; [
    cliphist
    glib
    gnome-software
    grim
    slurp
    satty
    wayland
    wl-clip-persist
    wlr-randr
  ];

  wayland.windowManager.mango = {
    enable = true;

    settings = {
      # Input — see https://mangowm.github.io/docs/configuration/basics
      xkb_rules_layout = "us";
      mouse_accel_profile = 2; # flat, per mango-config reference
      mouse_accel_speed = 0.0;
      sloppyfocus = 0; # matches niri/hyprland focus-follows-mouse=false
      cursor_theme = "Bibata-Modern-Ice";
      cursor_size = 24;

      # Appearance
      gappih = 5;
      gappiv = 5;
      gappoh = 10;
      gappov = 10;
      borderpx = 2;

      # HDR requires the Vulkan renderer, which drops scenefx support — so
      # blur/shadow (see git history for the previous settings) are traded
      # away here in favor of HDR on the two HDR10 ASUS VG289Q panels.
      # See https://mangowm.github.io/docs/configuration/monitors#hdr and
      # modules/WM/mango/monitors/desktop.nix for the per-output hdr:1.
      env = ["WLR_RENDERER,vulkan"];

      border_radius = 20;

      # Layouts — scroller matches niri/hyprland's scrolling-tape model
      circle_layout = "scroller,tile";
      scroller_default_proportion = 0.9;
      scroller_focus_center = 0;
      scroller_prefer_center = 0;
      scroller_prefer_overspread = 1;
    };
  };
}
