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

  # QSG_RHI_BACKEND intentionally NOT set globally — vulkan breaks quickshell/DMS
  # input handling and polkit on NVIDIA. Apps that need vulkan should set it themselves.
}
