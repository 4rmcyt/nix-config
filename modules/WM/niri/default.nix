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
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "niri";

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
  };

  home.packages = with pkgs; [
    cliphist
    glib
    gnome-software
    wayland
    wl-clip-persist
    xwayland-satellite
  ];

  programs.niri.settings = {
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
    hotkey-overlay.skip-at-startup = true;

    debug = {
      honor-xdg-activation-with-invalid-serial = true;
    };

    input = {
      keyboard.xkb.layout = "us";
      mouse.accel-speed = 0.0;
      mouse.accel-profile = "flat";
      focus-follows-mouse.enable = false;
    };

    cursor = {
      theme = "Bibata-Modern-Ice";
      size = 24;
    };

    environment = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      DISPLAY = ":0";
    };

    layout = {
      gaps = 8;
      border = {
        enable = true;
        width = 2;
      };
      focus-ring.enable = false;
      preset-column-widths = [
        {proportion = 1.0 / 3.0;}
        {proportion = 1.0 / 2.0;}
        {proportion = 2.0 / 3.0;}
      ];
      default-column-width = {
        proportion = 1.0 / 2.0;
      };
    };
  };
}
