{pkgs, ...}: let
  # Toggle both VG289 panels between 4K desktop (3840x2160 @ scale 2) and
  # native 1080p gaming (1920x1080 @ scale 1). The logical size stays 1920x1080
  # either way, so window/output positions don't move.
  #
  # Why not gamescope: nested gamescope on this NVIDIA + wlroots (mango) setup
  # corrupts the framebuffer ("eglInitialize failed", zero DRM format modifiers).
  # Switching the panel to a real 1080p signal gives pixel-perfect games with
  # zero scaling and no compositor in the middle.
  toggle-gaming-res = pkgs.writeShellApplication {
    name = "toggle-gaming-res";
    runtimeInputs = [pkgs.wlr-randr pkgs.libnotify pkgs.gnugrep];
    text = ''
      outputs=(DP-5 DP-6)
      if wlr-randr | grep -A25 '^DP-5' | grep -q 'Scale: 2'; then
        for o in "''${outputs[@]}"; do
          wlr-randr --output "$o" --mode 1920x1080 --scale 1
        done
        notify-send -t 2000 'Display' '1080p — gaming mode'
      else
        for o in "''${outputs[@]}"; do
          wlr-randr --output "$o" --mode 3840x2160 --scale 2
        done
        notify-send -t 2000 'Display' '4K — desktop mode'
      fi
    '';
  };
in {
  home.packages = [toggle-gaming-res];

  wayland.windowManager.mango.settings.bind = [
    "SUPER+SHIFT,G,spawn,toggle-gaming-res"
  ];
}
