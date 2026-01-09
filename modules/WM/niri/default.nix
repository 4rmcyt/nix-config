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
    # Display & System
    glib # System library
    wayland # Wayland library
    niri
    xwayland-satellite

    # Clipboard Management (DMS Integration)
    cliphist # Clipboard history backend
    wl-clip-persist # Clipboard persistence

    # DMS Utilities
    walker # Application launcher (fallback)

    # GNOME Applications (Best integration with DMS)
    gnome-text-editor # Modern text editor (replaces gedit)
    nautilus # File manager
    loupe # Image viewer (replaces eog)
    evince # PDF/document viewer

    # Optional GNOME Apps
    # gnome-calculator
    # gnome-calendar
    # gnome-weather
    # gnome-clocks

    # System Tools
    swaylock # Screen locker
    playerctl # Media player control
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
        enableKeybinds = true; # Sets static preset keybinds
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
      # ============================================
      # OUTPUTS
      # ============================================
      outputs = {
        "eDP-4" = {
          scale = 2.0;
        };
        "eDP-5" = {
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
        default-column-width = {proportion = 0.5;};
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

      # Window rules and spawn-at-startup moved to separate modules
    };
  };

  niri-flake.cache.enable = true;
}
