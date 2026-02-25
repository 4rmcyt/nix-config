{
  pkgs,
  ...
}: {
  imports = [
    ./binds.nix
    ./dms.nix
    ./startup.nix
    ./monitors.nix
    ./windowrules.nix
    ../hyprland/gtk.nix
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
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "niri";

    # NVIDIA for display (monitors connected to NVIDIA GPU)
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";
    __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";

    # VRR/G-Sync for NVIDIA
    __GL_GSYNC_ALLOWED = 1;
    __GL_VRR_ALLOWED = 1;

    # Qt
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };

  home.packages = with pkgs; [
    glib
    wayland
    cosmic-store

    # Clipboard Management (DMS Integration)
    cliphist
    wl-clip-persist

    # DMS Optional Features
    danksearch
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    configPackages = [
      pkgs.xdg-desktop-portal-gnome
    ];
    xdgOpenUsePortal = true;
  };

  # Package set by niri-flake NixOS module in parts/hosts/desktop/configuration.nix

  programs.niri.settings = {
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
    hotkey-overlay.skip-at-startup = true;

    input = {
      keyboard.xkb.layout = "us";
      focus-follows-mouse.enable = false;
    };

    cursor = {
      theme = "Bibata-Modern-Ice";
      size = 24;
    };

    environment = {
      NIXOS_OZONE_WL = "1";
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
      default-column-width = {proportion = 1.0 / 2.0;};
    };
  };
}
