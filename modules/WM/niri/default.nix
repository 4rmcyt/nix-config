{pkgs, ...}: {
  imports = [
    ./binds.nix
    ./exec-once.nix
    ./gtk.nix
    ./monitors.nix
    ./window-rules.nix
    ./vdirsyncer
  ];

  home.sessionVariables = {
    ANKI_WAYLAND = 1;
    CLUTTER_BACKEND = "wayland";
    GDK_BACKEND = "wayland,x11";
    LIBVA_DRIVER_NAME = "nvidia";
    MOZ_ENABLE_WAYLAND = 1;
    NIXOS_OZONE_WL = 1;
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QPA_PLATFORMTHEME = "gtk3";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    SDL_VIDEODRIVER = "wayland";
    XDG_CURRENT_DESKTOP = "Niri";
    XDG_SESSION_DESKTOP = "Niri";
    XDG_SESSION_TYPE = "wayland";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_GSYNC_ALLOWED = 1;
    __GL_VRR_ALLOWED = 1;
    NVD_BACKEND = "direct";
  };

  home.packages = with pkgs; [
    cliphist
    glib
    wayland
    wl-clip-persist
    xwayland-satellite
  ];

  programs.dank-material-shell = {
    enable = true;
    enableAudioWavelength = false;
    enableCalendarEvents = true;
    enableDynamicTheming = true;
    enableSystemMonitoring = true;
    enableVPN = false;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    settings = {
      # Enable GTK theming for FHS apps (Chromium, VSCode, etc.)
      gtkThemingEnabled = true;
      qtThemingEnabled = false; # Using QT_QPA_PLATFORMTHEME=gtk3 instead
      syncModeWithPortal = true;
      terminalsAlwaysDark = true;

      # Cursor settings
      cursorSettings = {
        theme = "Bibata-Modern-Classic";
        size = 24;
        niri = {
          hideWhenTyping = true;
          hideAfterInactiveMs = 0;
        };
      };
    };
  };

  systemd.user.targets.niri-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  programs.niri = {
    enable = true;

    settings = {
      environment = {};

      # Monitor configuration moved to ./monitors.nix
      # Cursor configuration managed by DMS settings

      layout = {
        border = {
          active.color = "#7dcfff";
          enable = true;
          inactive.color = "#414868";
          width = 1;
        };
        center-focused-column = "never";
        default-column-width = {
          proportion = 0.5;
        };
        focus-ring = {
          active.color = "#7dcfff";
          enable = true;
          inactive.color = "#414868";
          width = 2;
        };
        gaps = 5;
        preset-column-widths = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
        ];
      };

      prefer-no-csd = true;
      screenshot-path = "~/Pictures/Screenshots/niri_%Y-%m-%d_%H-%M-%S.png";
    };
  };
}
