{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./extensions.nix
    ./policies.nix
    ./preferences.nix
    inputs.zen-browser.homeModules.beta
  ];

  home.sessionVariables = {
    # Force Wayland backend for Zen Browser
    MOZ_ENABLE_WAYLAND = 1;
    MOZ_WAYLAND_USE_VAAPI = 1;

    # NVIDIA + VAAPI optimizations
    LIBVA_DRIVER_NAME = "nvidia";
    MOZ_USE_XINPUT2 = 1;
    MOZ_DISABLE_RDD_SANDBOX = 1;

    NVD_BACKEND = "direct";

    # Wayland-specific fixes
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORM = "wayland;xcb";
    SDL_VIDEODRIVER = "wayland";

    # NVIDIA + X11 optimizations
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = 1;
    WLR_RENDERER = "vulkan";

    # Mozilla optimizations for X11
    MOZ_WEBRENDER = 1;
    MOZ_ACCELERATED = 1;
    MOZ_X11_EGL = 0;

    # NVIDIA-specific browser fixes
    __GL_GSYNC_ALLOWED = 1;
    __GL_VRR_ALLOWED = 1;
    WEBKIT_DISABLE_COMPOSITING_MODE = 0;
  };
  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [
      pkgs.browserpass
      pkgs.kdePackages.plasma-browser-integration
      pkgs.firefoxpwa
    ];
  };
}
