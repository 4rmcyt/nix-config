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

      # HDR requires the vulkan renderer, and mango's own docs say HDR only
      # works on the `wl-only` branch, since scenefx (which `main` links
      # unconditionally) doesn't support that renderer — see the mango
      # input comment in flake.nix and docs/Architecture.md for the full
      # trail. Trade-off: `wl-only`'s meson.build drops libscenefx entirely,
      # so every scenefx-dependent visual (blur, shadows, AND border_radius
      # — corner radii are drawn via scenefx's fx_corner_radii/
      # wlr_scene_shadow_create, not plain wlroots) is gone with it, not
      # just blur/shadow. `border_radius` is not a recognized config
      # keyword on this branch at all — setting it fails mango-config.conf's
      # build (`[ERROR]: Unknown keyword: border_radius`), it doesn't just
      # no-op.
      #
      # WLR_RENDERER is NOT set here via `env=` — wlroots picks the renderer
      # backend before mango ever reads config.conf, so a config-file `env=`
      # directive is too late (confirmed: had no effect on `mmsg get
      # monitor`'s is_hdr). It's set on greetd's exec instead — see
      # parts/hosts/desktop/configuration.nix.

      # Layouts — scroller matches niri/hyprland's scrolling-tape model
      circle_layout = "scroller,tile";
      scroller_default_proportion = 0.9;
      scroller_focus_center = 0;
      scroller_prefer_center = 0;
      scroller_prefer_overspread = 1;
    };
  };
}
