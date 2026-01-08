{pkgs, ...}: {
  # ============================================
  # MODULE IMPORTS
  # ============================================
  imports = [
    # Core Hyprland Configuration
    # ./binds.nix
    # ./windowrules.nix
    # ./exec-once.nix

    # Lock & Security
    # ./hyprlock.nix
    # ./swaylock.nix

    # UI Components
    # ./waybar
    # ./swaync
    # ./launcher
    # ./wlogout.nix

    # Utilities
    # ./waypaper
    # ./swayosd.nix

    # System Integration
    # ./xdg-mimes.nix
    # ./gtk.nix
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
    QT_QPA_PLATFORM = "wayland;xcb;qt6ct";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_STYLE_OVERRIDE = "kvantum";
    DISABLE_QT5_COMPAT = 0;

    # WLR
    WLR_RENDERER = "vulkan";

    # Utilities
    DIRENV_LOG_FORMAT = "";
    GTK_THEME = "Kanagawa-B";
    GRIMBLAST_HIDE_CURSOR = 0;
  };

  # ============================================
  # HYPRLAND PACKAGES
  # ============================================
  home.packages = with pkgs; [
    # Display & System
    glib # System library
    wayland # Wayland library

    # File Manager & Applications
    cosmic-store
    kdePackages.qt6ct
    kdePackages.ark # Archive manager
    kdePackages.dolphin # File manager
    kdePackages.gwenview # Image viewer
    kdePackages.kate # Text editor
    kdePackages.okular # PDF viewer
  ];

  programs.dankMaterialShell = {
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

  # ============================================
  # SYSTEMD INTEGRATION
  # ============================================
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;

    xwayland = {
      enable = true;
    };

    systemd.enable = true;

    settings = {
      monitor = [
        "DP-4,3840x2160@59.997,0x0,2,bitdepth,10"
        "DP-5,3840x2160@59.997,1920x0,2,bitdepth,10"
      ];
      "$mod" = "SUPER";
    };

    extraConfig = ''
      # hyprlang noerror true
        source = ~/.config/hypr/monitors.conf
        source = ~/.config/hypr/workspaces.conf
      # hyprlang noerror false
    '';
  };
}
