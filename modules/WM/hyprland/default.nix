{pkgs, ...}: {
  # ============================================
  # MODULE IMPORTS
  # ============================================
  imports = [
    ./exec-once.nix
    ./settings.nix
    ./binds.nix
    ./windowrules.nix
    ./hyprlock.nix
    ./waybar
    ./waypaper
    ./swayosd.nix
    ./swaylock.nix
    ./launcher
    ./swaync
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

    # WLR - Removed WLR_DRM_NO_ATOMIC and WLR_NO_HARDWARE_CURSORS for better VRR
    # Hardware cursors now managed via Hyprland cursor settings
    WLR_RENDERER = "vulkan";

    # Other
    SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
    DIRENV_LOG_FORMAT = "";
    GTK_THEME = "Colloid-Green-Dark-Gruvbox";
    GRIMBLAST_HIDE_CURSOR = 0;
  };

  # ============================================
  # HYPRLAND PACKAGES
  # ============================================
  home.packages = with pkgs; [
    # Core Wayland Tools
    swww
    grim
    slurp
    grimblast
    wl-clip-persist
    cliphist
    wf-recorder

    # Hyprland Utilities
    hyprpicker
    hyprpaper
    hyprsunset
    wlogout
    swayosd

    # System Libraries
    glib
    wayland
    direnv

    # Display Management
    nwg-displays

    # KDE Applications
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.okular
    kdePackages.ark
    kdePackages.gwenview
    cosmic-store
  ];

  # ============================================
  # SYSTEMD INTEGRATION
  # ============================================
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  gnome.gnome-keyring.enable = true;

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
