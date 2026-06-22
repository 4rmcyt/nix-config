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
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };

  home.packages = with pkgs; [
    glib
    wayland
    gnome-software

    # Clipboard Management
    cliphist
    wl-clip-persist
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
