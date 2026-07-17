_: {
  # cm,hdr + bitdepth,10 enables real HDR10 output (wide gamut + PQ transfer),
  # unlike niri which currently has no HDR renderer/backend support at all.
  # See https://wiki.hypr.land/0.52.0/Configuring/Monitors/#color-management-presets
  # If desktop SDR content looks washed out in this mode, tune per-monitor
  # sdr_min_luminance / sdr_max_luminance (same monitor line, comma-separated).
  wayland.windowManager.hyprland.settings.monitor = [
    "ASUSTek COMPUTER INC ASUS VG289 0x00011FC7, 3840x2160@60, 0x0, 2, cm, hdr, bitdepth, 10"
    "ASUSTek COMPUTER INC ASUS VG289 0x00011E65, 3840x2160@60, 1920x0, 2, cm, hdr, bitdepth, 10"
  ];
}
