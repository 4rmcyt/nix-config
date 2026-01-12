{pkgs, ...}: {
  imports = [
    ./binds.nix
    ./exec-once.nix
    ./gtk.nix
    ./window-rules.nix
  ];

  home.sessionVariables = {
    # Wayland/Ozone
    NIXOS_OZONE_WL = 1;
    GDK_BACKEND = "wayland,x11";
    ANKI_WAYLAND = 1;
    MOZ_ENABLE_WAYLAND = 1;
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "MangoWC";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "MangoWC";

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
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  home.packages = with pkgs; [
    # Display & System
    glib # System library
    wayland # Wayland library
    xwayland-satellite

    # Clipboard Management (DMS Integration)
    cliphist # Clipboard history backend
    wl-clip-persist # Clipboard persistence
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
  };

  # ============================================
  # SYSTEMD INTEGRATION
  # ============================================
  # MangoWC session target for DMS integration
  systemd.user.targets.mango-session = {
    Unit = {
      Description = "MangoWC Session Target";
      Requires = "graphical-session.target";
      After = "graphical-session.target";
      Wants = "xdg-desktop-autostart.target";
    };
  };

  # Link DMS service to MangoWC session
  systemd.user.services.dms = {
    Unit = {
      PartOf = ["mango-session.target"];
    };
    Install = {
      WantedBy = ["mango-session.target"];
    };
  };
}
