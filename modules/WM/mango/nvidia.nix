_: {
  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    GSK_RENDERER = "ngl";
    # Without this, Firefox's RDD process sandbox blocks nvidia-vaapi-driver
    # from reaching the NVIDIA driver, silently falling back to software
    # video decode (dav1d/ffvpx) even though VAAPI is otherwise set up
    # correctly. Documented fix: https://github.com/elFarto/nvidia-vaapi-driver#firefox
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  # mango reads its own config-file `env=KEY,VALUE` lines before the
  # compositor finishes initializing (see
  # https://mangowm.github.io/docs/configuration/basics) — session vars
  # alone aren't guaranteed live in time, so set them here too via mango's
  # own env directive.
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
