{ pkgs, ... }:
{
  # ============================================
  # MODULE IMPORTS
  # ============================================
  imports = [
    # Core Hyprland Configuration
    ./binds.nix
    ./exec-once.nix
    ./gtk.nix
    ./monitors.nix
    ./windowrules.nix
  ];

  home.sessionVariables = {
    # Wayland/Ozone
    NIXOS_OZONE_WL = 1;
    GDK_BACKEND = "wayland,x11";
    ANKI_WAYLAND = 1;
    MOZ_ENABLE_WAYLAND = 1;
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";

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
    # Note: ELECTRON_OZONE_PLATFORM_HINT removed - NIXOS_OZONE_WL handles Electron/Chromium Wayland support
  };

  # ============================================
  # HYPRLAND PACKAGES
  # ============================================

  home.packages = with pkgs; [
    # Display & System
    glib # System library
    wayland # Wayland library
    xwayland-satellite

    # Clipboard Management (DMS Integration)
    cliphist # Clipboard history backend
    wl-clip-persist # Clipboard persistence
  ];
  programs = {
    dank-material-shell = {
      enable = true;
      systemd = {
        enable = true; # Systemd service for auto-start
        restartIfChanged = true; # Auto-restart dms.service when dankMaterialShell changes
      };
      # Core features
      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableVPN = false; # VPN management widget
      enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      enableAudioWavelength = false; # Audio visualizer (cava)
      enableCalendarEvents = true; # Calendar integration (khal)
      settings = {
        # Enable GTK theming for FHS apps (Chromium, VSCode, etc.)
        gtkThemingEnabled = true;
        qtThemingEnabled = false; # Using QT_QPA_PLATFORMTHEME=gtk3 instead
        syncModeWithPortal = true;
        terminalsAlwaysDark = true;
      };
    };
  };

  # ============================================
  # SYSTEMD INTEGRATION
  # ============================================
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
    };

    systemd.enable = true;

    plugins = [
      pkgs.hyprlandPlugins.hyprscrolling
    ];

    settings = {
      # Monitor configuration moved to ./monitors.nix
      "$mod" = "SUPER";

      # Enable VRR globally
      misc = {
        vrr = 1;
      };

      # Hyprscroller plugin settings (matching niri layout)
      plugin = {
        scroller = {
          # Column layout settings
          column_default_width = "onehalf"; # 50% width, matching niri's 0.5 proportion
          focus_wrap = false; # Don't wrap focus at edges

          # Column width cycling (matches niri preset-column-widths)
          column_widths = "onethird onehalf twothirds one"; # 33%, 50%, 66%, 100%

          # Window/column gaps (matching niri's gaps = 5)
          gaps_in = 5;
          gaps_out = 5;

          # Center focused column behavior (matching niri center-focused-column = "never")
          center_column = false;
        };
      };
    };

    extraConfig = ''
      # hyprlang noerror true
        source = ~/.config/hypr/monitors.conf
        source = ~/.config/hypr/workspaces.conf
        # DMS-generated configs
        source = ~/.config/hypr/dms/colors.conf
        source = ~/.config/hypr/dms/cursor.conf
        source = ~/.config/hypr/dms/layout.conf
        source = ~/.config/hypr/dms/outputs.conf
      # hyprlang noerror false
    '';
  };
}
