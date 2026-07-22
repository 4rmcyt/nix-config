_: {
  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    GSK_RENDERER = "ngl";
  };

  # Per https://wiki.hypr.land/Nvidia/#environment-variables: these must be set
  # via Hyprland's own env (not just session vars), since the compositor
  # reads them before the graphical session's environment is fully live.
  wayland.windowManager.hyprland.settings.env = [
    {_args = ["LIBVA_DRIVER_NAME" "nvidia"];}
    {_args = ["__GLX_VENDOR_LIBRARY_NAME" "nvidia"];}
    {_args = ["NVD_BACKEND" "direct"];}
  ];

  home.file.".nv/nvidia-application-profiles-rc".text = builtins.toJSON {
    rules = [
      {
        pattern = {
          feature = "procname";
          matches = "Hyprland";
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
