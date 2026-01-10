{pkgs, ...}: {
  # ============================================
  # MODULE IMPORTS
  # ============================================
  imports = [
    # Core Niri Configuration
    ./binds.nix
    ./window-rules.nix
    ./exec-once.nix
    ./gtk.nix
  ];

  home.sessionVariables = {
    # Wayland/Ozone
    NIXOS_OZONE_WL = 1;
    GDK_BACKEND = "wayland,x11";
    ANKI_WAYLAND = 1;
    MOZ_ENABLE_WAYLAND = 1;
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "Niri";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Niri";

    # Nvidia-specific (hybrid AMD+Nvidia setup)
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";

    # VRR/G-Sync - Enable for Nvidia
    __GL_GSYNC_ALLOWED = 1;
    __GL_VRR_ALLOWED = 1;

    # Qt
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QPA_PLATFORMTHEME = "gtk3"; # Use GTK3 passthrough for Qt (DMS recommended)
  };

  # ============================================
  # NIRI PACKAGES
  # ============================================
  home.packages = with pkgs; [
    glib # System library
    wayland # Wayland library
    xwayland-satellite
    cliphist # Clipboard history backend
    wl-clip-persist # Clipboard persistence
  ];

  programs = {
    dankMaterialShell = {
      enable = true;
      systemd = {
        enable = true; # Systemd service for auto-start
        restartIfChanged = true; # Auto-restart dms.service when dankMaterialShell changes
      };
      # Core features
      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableClipboard = true; # Clipboard history manager
      enableVPN = false; # VPN management widget
      enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      enableAudioWavelength = false; # Audio visualizer (cava)
      enableCalendarEvents = true; # Calendar integration (khal)
      niri = {
        enableKeybinds = false; # Using custom keybinds in binds.nix
        enableSpawn = true; # Auto-start DMS with niri and cliphist, if enabled
      };
    };
  };

  # ============================================
  # SYSTEMD INTEGRATION
  # ============================================
  systemd.user.targets.niri-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  programs.niri = {
    enable = true;

    settings = {
      outputs = {
        "DP-4" = {
          mode = {
            width = 3840;
            height = 2160;
            refresh = 60.0;
          };
          position = {
            x = 0;
            y = 0;
          };
          scale = 2.0;
        };
        "DP-5" = {
          mode = {
            width = 3840;
            height = 2160;
            refresh = 60.0;
          };
          position = {
            x = 1920;
            y = 0;
          };
          scale = 2.0;
        };
      };

      # ============================================
      # LAYOUT - DMS Recommended Settings
      # ============================================
      layout = {
        gaps = 5; # DMS recommended: 5px gaps
        center-focused-column = "never";
        preset-column-widths = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
        ];
        default-column-width = {
          proportion = 0.5;
        };
        focus-ring = {
          enable = true;
          width = 2;
          active.color = "#7dcfff";
          inactive.color = "#414868";
        };
        border = {
          enable = true;
          width = 1;
          active.color = "#7dcfff";
          inactive.color = "#414868";
        };
      };

      # ============================================
      # PREFER NO SERVER-SIDE DECORATIONS
      # ============================================
      prefer-no-csd = true;

      # Screenshot path
      screenshot-path = "~/Pictures/Screenshots/niri_%Y-%m-%d_%H-%M-%S.png";
    };
  };
}
