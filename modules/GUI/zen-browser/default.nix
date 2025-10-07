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
    GDK_BACKEND = "x11";
    MOZ_ENABLE_WAYLAND = 0;
    DISABLE_WAYLAND = 1;
    QT_QPA_PLATFORM = "xcb";

    # NVIDIA VAAPI
    LIBVA_DRIVER_NAME = "nvidia";
    VAAPI_DISABLE_INTERLACE = 1;
    MOZ_DISABLE_RDD_SANDBOX = 1;
    
    NVD_BACKEND = "direct";

    # NVIDIA + X11 optimizations
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # WLR_NO_HARDWARE_CURSORS = 1;
    # WLR_RENDERER = "vulkan";

    # Mozilla optimizations for X11
    MOZ_WEBRENDER = 1;
    MOZ_USE_XINPUT2 = 1;

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
