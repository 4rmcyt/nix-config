# monitorrule=name:Regex,make:Values,model:Values,serial:Values,Param:Values
# See https://mangowm.github.io/docs/configuration/monitors
#
# Same two ASUS VG289 panels as modules/WM/hyprland/monitors/desktop.nix,
# matched by make+model+serial (mango has no single "desc" field like
# Hyprland's wlr-output desc string, which packs make+model+serial into one).
#
# No hdr:1 here — mango's HDR (hdr/hdr_force/hdr_*_lum) only works on its
# wl-only branch behind WLR_RENDERER=vulkan, and that branch drops scenefx
# (blur/shadow), which modules/WM/mango/default.nix relies on. nixpkgs'
# mango package builds the mainline (non-vulkan) branch, so HDR isn't
# reachable here regardless.
_: {
  wayland.windowManager.mango.settings.monitorrule = [
    "make:ASUSTek COMPUTER INC,model:ASUS VG289,serial:0x00011FC7,width:3840,height:2160,refresh:60,x:0,y:0,scale:2"
    "make:ASUSTek COMPUTER INC,model:ASUS VG289,serial:0x00011E65,width:3840,height:2160,refresh:60,x:1920,y:0,scale:2"
  ];
}
