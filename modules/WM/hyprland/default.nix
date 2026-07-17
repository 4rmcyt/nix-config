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
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";

    # Qt
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland;xcb";

    # Quickshell (noctalia-shell) icon theme override — bypasses Qt/GTK theme
    # autodetection, which noctalia-shell's Quickshell.iconPath() does not
    # reliably follow. See https://quickshell.org/docs/master/types/Quickshell/Quickshell
    QS_ICON_THEME = "Tela-circle-dark";
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
    qt5ctSettings.Appearance.icon_theme = "Tela-circle-dark";
    qt6ctSettings.Appearance.icon_theme = "Tela-circle-dark";
  };

  home.packages = with pkgs; [
    cliphist
    glib
    gnome-software
    grimblast
    wayland
    wl-clip-persist
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    configType = "lua";

    # UWSM manages graphical-session.target itself; HM's own systemd
    # integration would conflict with it (per NixOS wiki + Hyprland wiki
    # warning on withUWSM).
    systemd.enable = false;

    settings = {
      env = [
        {_args = ["NIXOS_OZONE_WL" "1"];}
        {_args = ["ELECTRON_OZONE_PLATFORM_HINT" "wayland"];}
      ];

      config = {
        general = {
          gaps_in = 5;
          gaps_out = 10;
          layout = "dwindle";
        };

        decoration = {
          rounding = 20;
          rounding_power = 2;

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 2;
            vibrancy = 0.1696;
          };
        };

        input = {
          kb_layout = "us";
          sensitivity = 0.0;
          accel_profile = "flat";
          follow_mouse = 0;
        };
      };

      # noctalia bar/panel backgrounds — blur behind them, matching
      # https://docs.noctalia.dev/v4/getting-started/compositor-settings/hyprland/
      layer_rule = {
        _args = [
          {
            name = "noctalia-blur";
            match = {namespace = "^noctalia-background-.*$";};
            blur = true;
            blur_popups = true;
            ignore_alpha = 0.5;
          }
        ];
      };
    };
  };
}
