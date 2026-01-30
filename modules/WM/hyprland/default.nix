{pkgs, ...}: {
  # ============================================
  # MODULE IMPORTS
  # ============================================
  imports = [
    # Core Hyprland Configuration
    ./binds.nix
    ./dms.nix
    ./exec-once.nix
    ./gtk.nix
    ./hyprsession.nix
    ./monitors.nix
    ./windowrules.nix
    # Shared modules
    ../matugen
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

    # NVIDIA for display (monitors connected to NVIDIA GPU)
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";
    __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";

    # Multi-GPU: Use NVIDIA (card2) for display
    AQ_DRM_DEVICES = "/dev/dri/card2:/dev/dri/card1";

    # VRR/G-Sync for NVIDIA
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
    cosmic-store

    # Clipboard Management (DMS Integration)
    cliphist # Clipboard history backend
    wl-clip-persist # Clipboard persistence

    # DMS Optional Features
    danksearch # Indexed filesystem search for DMS launcher
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
    configPackages = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
    xdgOpenUsePortal = true;
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

    settings = {
      # Monitor configuration moved to ./monitors.nix
      "$mod" = "SUPER";

      # Enable VRR globally
      misc = {
        vrr = 1;
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
