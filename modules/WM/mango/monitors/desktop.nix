# monitorrule=name:Regex,make:Values,model:Values,serial:Values,Param:Values
# See https://mangowm.github.io/docs/configuration/monitors
#
# Same two ASUS VG289 panels as modules/WM/hyprland/monitors/desktop.nix,
# matched by make+model+serial (mango has no single "desc" field like
# Hyprland's wlr-output desc string, which packs make+model+serial into one).
#
# hdr:1 — both panels are ASUS TUF VG289Q, which are HDR10-certified, so
# their EDID should advertise BT.2020/PQ correctly without needing
# hdr_force:1. Requires env=WLR_RENDERER,vulkan (see default.nix), which
# drops scenefx (blur/shadow) — a deliberate trade-off, not a bug.
_: {
  wayland.windowManager.mango.settings.monitorrule = [
    "make:ASUSTek COMPUTER INC,model:ASUS VG289,serial:0x00011FC7,width:3840,height:2160,refresh:60,x:0,y:0,scale:2,hdr:1"
    "make:ASUSTek COMPUTER INC,model:ASUS VG289,serial:0x00011E65,width:3840,height:2160,refresh:60,x:1920,y:0,scale:2,hdr:1"
  ];
}
