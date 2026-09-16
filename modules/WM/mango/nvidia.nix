_: {
  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    GSK_RENDERER = "ngl";
    # Without it, Firefox's RDD sandbox blocks nvidia-vaapi-driver, silently falling
    # back to software decode: https://github.com/elFarto/nvidia-vaapi-driver#firefox
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  # session vars alone aren't guaranteed live before the compositor finishes
  # initializing, so also set them via mango's own env directive.
  wayland.windowManager.mango.settings.env = [
    "LIBVA_DRIVER_NAME,nvidia"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    "NVD_BACKEND,direct"
    "MOZ_DISABLE_RDD_SANDBOX,1"
  ];

  home.file.".nv/nvidia-application-profiles-rc".text = builtins.toJSON {
    rules = [
      {
        pattern = {
          feature = "procname";
          matches = "mango";
        };
        profile = "No VidMem Reuse";
      }
    ];
    profiles = [
      {
        name = "No VidMem Reuse";
        settings = [
          {
            key = "GLVidHeapReuseRatio";
            value = 0;
          }
        ];
      }
    ];
  };
}
