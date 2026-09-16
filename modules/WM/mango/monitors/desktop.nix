# hdr:1 alone never took effect (`mmsg get all-monitors` → is_hdr false): mango gates
# HDR on what the EDID actually advertises, not the panel's marketing HDR10 claim.
# hdr_force skips those EDID checks but not the renderer requirement, so
# WLR_RENDERER=vulkan (default.nix) is still required. Also needs the `wl-only`
# branch (flake.nix) — `main`'s scenefx doesn't support the vulkan renderer HDR needs.
_: {
  wayland.windowManager.mango.settings.monitorrule = [
    "make:ASUSTek COMPUTER INC,model:ASUS VG289,serial:0x00011FC7,width:3840,height:2160,refresh:60,x:0,y:0,scale:2,hdr:1,hdr_force:1"
    "make:ASUSTek COMPUTER INC,model:ASUS VG289,serial:0x00011E65,width:3840,height:2160,refresh:60,x:1920,y:0,scale:2,hdr:1,hdr_force:1"
  ];
}
