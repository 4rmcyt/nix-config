_: {
  # cm,hdr + bitdepth,10 enables real HDR10 output (wide gamut + PQ transfer),
  # unlike niri which currently has no HDR renderer/backend support at all.
  # See https://wiki.hypr.land/0.52.0/Configuring/Monitors/#color-management-presets
  # NOTE: Hyprland (unlike niri) requires a "desc:" prefix to match a monitor
  # by its EDID description string — without it the rule silently fails to
  # match and Hyprland falls back to auto scale/sRGB (confirmed live via
  # hyprctl: scale stuck at 1.5, colorManagementPreset stuck at "srgb").
  # sdrbrightness boosts perceived brightness of SDR content (desktop, browser)
  # while in HDR mode — default 1.0 looked noticeably duller than plain SDR.
  # sdr_min_luminance/sdr_max_luminance (the "proper" EDID-override knobs) are
  # NOT available in classic comma-list syntax — confirmed "invalid syntax"
  # live via hyprctl; they only exist in the "monitorv2 {}" block syntax.
  wayland.windowManager.hyprland.settings.monitor = [
    "desc:ASUSTek COMPUTER INC ASUS VG289 0x00011FC7, 3840x2160@60, 0x0, 2, cm, hdr, bitdepth, 10, sdrbrightness, 1.6"
    "desc:ASUSTek COMPUTER INC ASUS VG289 0x00011E65, 3840x2160@60, 1920x0, 2, cm, hdr, bitdepth, 10, sdrbrightness, 1.6"
  ];
}
