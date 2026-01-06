{pkgs, ...}: {
  # ============================================
  # MODULE IMPORTS
  # ============================================
  imports = [
    # Core Hyprland Configuration
    ./settings.nix
    ./binds.nix
    ./windowrules.nix
    ./exec-once.nix

    # Lock & Security
    ./hyprlock.nix
    ./swaylock.nix

    # UI Components
    ./waybar
    ./swaync
    ./launcher
    ./wlogout.nix

    # Utilities
    ./waypaper
    ./swayosd.nix

    # System Integration
    ./xdg-mimes.nix
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
    # Core Wayland/Hyprland Tools
    grim # Screenshot utility
    grimblast # Screenshot wrapper
    hyprpaper # Wallpaper daemon
    hyprpicker # Color picker
    hyprsunset # Blue light filter
    slurp # Region selector
    swayosd # OSD daemon
    swww # Animated wallpaper daemon
    wf-recorder # Screen recorder
    wlogout # Logout menu

    # Clipboard Management
    cliphist # Clipboard history
    wl-clip-persist # Clipboard persistence

    # Display & System
    direnv # Environment loader
    glib # System library
    nwg-displays # Display configuration
    wayland # Wayland library

    # File Manager & Applications
    cosmic-store
    kdePackages.ark # Archive manager
    kdePackages.dolphin # File manager
    kdePackages.gwenview # Image viewer
    kdePackages.kate # Text editor
    kdePackages.okular # PDF viewer
  ];

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

    settings.monitor = [
      "DP-4,3840x2160@59.997,0x0,2,bitdepth,10"
      "DP-5,3840x2160@59.997,1920x0,2,bitdepth,10"
    ];

    extraConfig = ''
      # hyprlang noerror true
        source = ~/.config/hypr/monitors.conf
        source = ~/.config/hypr/workspaces.conf
      # hyprlang noerror false
    '';
  };
}
