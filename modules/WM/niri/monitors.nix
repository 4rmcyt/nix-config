_: {
  programs.niri.settings.outputs = {
    "DP-4" = {
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
      variable-refresh-rate = true;
    };
    "DP-5" = {
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
      variable-refresh-rate = true;
    };
  };
}
