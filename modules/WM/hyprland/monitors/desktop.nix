_: let
  monitor = args: {_args = [args];};
  workspaceRule = args: {_args = [args];};

  leftMonitor = "desc:ASUSTek COMPUTER INC ASUS VG289 0x00011FC7";
  rightMonitor = "desc:ASUSTek COMPUTER INC ASUS VG289 0x00011E65";
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
      output = leftMonitor;
      mode = "3840x2160@60";
      position = "0x0";
      scale = 2;
      bitdepth = 10;
      cm = "hdr";
      sdr_max_luminance = 220;
    })
    (monitor {
      output = rightMonitor;
      mode = "3840x2160@60";
      position = "1920x0";
      scale = 2;
      bitdepth = 10;
      cm = "hdr";
      sdr_max_luminance = 220;
    })
  ];

  # Static workspace-to-monitor binding. Without this, hyprflow's session
  # restore (modules/WM/hyprland/hyprflow.nix) has no effect on monitor
  # placement — it only dispatches movetoworkspacesilent by workspace ID
  # (see restore_single_client in hyprflow's src/restore.rs), relying on
  # Hyprland itself to route the workspace to the right monitor. With no
  # static binding, a freshly created workspace goes to whichever monitor
  # is currently focused at restore time, so every window ends up on one
  # screen after reboot. Odd workspaces → left monitor, even → right.
  wayland.windowManager.hyprland.settings.workspace_rule = [
    (workspaceRule {
      workspace = "1";
      monitor = leftMonitor;
      default = true;
    })
    (workspaceRule {
      workspace = "3";
      monitor = leftMonitor;
    })
    (workspaceRule {
      workspace = "5";
      monitor = leftMonitor;
    })
    (workspaceRule {
      workspace = "7";
      monitor = leftMonitor;
    })
    (workspaceRule {
      workspace = "9";
      monitor = leftMonitor;
    })
    (workspaceRule {
      workspace = "2";
      monitor = rightMonitor;
      default = true;
    })
    (workspaceRule {
      workspace = "4";
      monitor = rightMonitor;
    })
    (workspaceRule {
      workspace = "6";
      monitor = rightMonitor;
    })
    (workspaceRule {
      workspace = "8";
      monitor = rightMonitor;
    })
  ];
}
