{pkgs, ...}: {
  imports = [
    ./binds.nix
    ./gaming-res.nix
    ./startup.nix
    ./windowrules.nix
    ../gtk.nix
    ../qt-common.nix
  ];

  home.sessionVariables = {
    ANKI_WAYLAND = "1";
    MOZ_ENABLE_WAYLAND = "1";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "mango";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "mango";

    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland;xcb";
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
    wl-clipboard
    wlr-randr
  ];

  wayland.windowManager.mango = {
    enable = true;

    settings = {
      xkb_rules_layout = "us";
      mouse_accel_profile = 2; # flat, per mango-config reference
      mouse_accel_speed = 0.0;
      sloppyfocus = 0; # matches niri/hyprland focus-follows-mouse=false
      cursor_theme = "Bibata-Modern-Ice";
      cursor_size = 24;

      gappih = 5;
      gappiv = 5;
      gappoh = 10;
      gappov = 10;
      borderpx = 2;

      # `wl-only` branch (see flake.nix) drops libscenefx entirely, so blur, shadows,
      # and border_radius (drawn via scenefx, not plain wlroots) are all unavailable —
      # border_radius isn't even a recognized keyword here, setting it fails the build.
      #
      # WLR_RENDERER is NOT set here via `env=`: wlroots picks the renderer backend
      # before mango reads config.conf, so it's too late here — set on greetd's exec
      # instead, see parts/hosts/desktop/configuration.nix.

      # scroller matches niri/hyprland's scrolling-tape model
      circle_layout = "scroller,tile";
      scroller_default_proportion = 0.9;
      scroller_focus_center = 0;
      scroller_prefer_center = 0;
      scroller_prefer_overspread = 1;
    };
  };
}
