_: let
  monitor = args: {_args = [args];};
in {
  # cm="hdr" + bitdepth=10 enables real HDR10 output (wide gamut + PQ transfer),
  # unlike niri which currently has no HDR renderer/backend support at all.
  # See https://wiki.hypr.land/Configuring/Basics/Monitors/
  #
  # sdr_max_luminance (proper EDID-override knob, default 80) IS supported here
  # in the Lua monitor object — unlike classic hyprlang comma-list syntax,
  # where it hard-errored ("invalid syntax"). Raised from default 80 to 220
  # per https://wiki.hypr.land — desktop SDR content looked noticeably duller
  # than plain SDR at the default.
  wayland.windowManager.hyprland.settings.monitor = [
    (monitor {
      output = "desc:ASUSTek COMPUTER INC ASUS VG289 0x00011FC7";
      mode = "3840x2160@60";
      position = "0x0";
      scale = 2;
      bitdepth = 10;
      cm = "hdr";
      sdr_max_luminance = 220;
    })
    (monitor {
      output = "desc:ASUSTek COMPUTER INC ASUS VG289 0x00011E65";
      mode = "3840x2160@60";
      position = "1920x0";
      scale = 2;
      bitdepth = 10;
      cm = "hdr";
      sdr_max_luminance = 220;
    })
  ];
}
