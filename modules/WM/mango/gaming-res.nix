{pkgs, ...}: let
  # Not gamescope: nested gamescope on this NVIDIA + wlroots setup corrupts the
  # framebuffer ("eglInitialize failed", zero DRM format modifiers) — switching the
  # panel to a real 1080p signal gives pixel-perfect games with no compositor scaling.
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
