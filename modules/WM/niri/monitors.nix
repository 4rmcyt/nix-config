_: {
  programs.niri.settings.outputs = {
    "DP-1" = {
      mode = {
        width = 3840;
        height = 2160;
        refresh = 60.0;
      };
      scale = 2.0;
      position = {
        x = 0;
        y = 0;
      };
      variable-refresh-rate = false;
    };
    "DP-2" = {
      mode = {
        width = 3840;
        height = 2160;
        refresh = 60.0;
      };
      scale = 2.0;
      position = {
        x = 1920;
        y = 0;
      };
      variable-refresh-rate = false;
    };
  };
}
