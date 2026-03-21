_: {
  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";
    __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";
    __GL_GSYNC_ALLOWED = 1;
    __GL_VRR_ALLOWED = 1;
  };

  # QSG_RHI_BACKEND=vulkan must be in niri's environment block so spawned
  # processes (DMS/quickshell) inherit it — OpenGL context creation fails
  # on NVIDIA with the default EGL backend
  programs.niri.settings.environment.QSG_RHI_BACKEND = "vulkan";
}
