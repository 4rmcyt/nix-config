_: {
  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";
    __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";
    __GL_GSYNC_ALLOWED = 1;
    __GL_VRR_ALLOWED = 1;
    GSK_RENDERER = "gl";
  };

  home.file.".nv/nvidia-application-profiles-rc".text = builtins.toJSON {
    rules = [
      {
        pattern = {
          feature = "procname";
          matches = "niri";
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
