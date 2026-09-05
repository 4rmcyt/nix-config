# monitorrule=name:Regex,make:Values,model:Values,serial:Values,Param:Values
# See https://mangowm.github.io/docs/configuration/monitors
#
# Same two ASUS VG289 panels as the old Hyprland config (removed), matched
# by make+model+serial (mango has no single "desc" field like Hyprland's
# wlr-output desc string, which packs make+model+serial into one).
#
# hdr:1,hdr_force:1 — both panels are ASUS TUF VG289Q ("HDR10-certified"),
# but live testing (`mmsg get all-monitors` → is_hdr) showed hdr:1 alone
# never took effect: mango's output_supports_hdr() (src/ext-protocol/hdr.h)
# gates on wlr_output->supported_primaries/supported_transfer_functions,
# i.e. what the EDID actually advertises to wlroots — not the marketing
# name — and these panels' EDID apparently doesn't clear that bar. hdr_force
# skips those two EDID checks; it does NOT skip the third (renderer must
# support output_color_transform), which is why WLR_RENDERER=vulkan (see
# default.nix) is still required.
#
# HDR only actually works on mangowm/mango's `wl-only` branch (see the
# mango input comment in flake.nix) — `main` links scenefx unconditionally,
# and scenefx doesn't support the vulkan renderer output_color_transform
# needs, so is_hdr stays false on `main` no matter what's set here.
_: {
  wayland.windowManager.mango.settings.monitorrule = [
    "make:ASUSTek COMPUTER INC,model:ASUS VG289,serial:0x00011FC7,width:3840,height:2160,refresh:60,x:0,y:0,scale:2,hdr:1,hdr_force:1"
    "make:ASUSTek COMPUTER INC,model:ASUS VG289,serial:0x00011E65,width:3840,height:2160,refresh:60,x:1920,y:0,scale:2,hdr:1,hdr_force:1"
  ];
}
