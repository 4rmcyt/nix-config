{lib, ...}: let
  inherit (lib.generators) mkLuaInline;

  noctalia = cmd: ''hl.dsp.exec_cmd("noctalia-shell ipc call ${cmd}")'';
  exec = cmd: ''hl.dsp.exec_cmd(${builtins.toJSON cmd})'';

  # keys: "MOD + KEY" string. dispatcherLua: raw lua expression (string).
  # flags: attrset of bind flags, or null.
  bind = keys: dispatcherLua: flags: {
    _args =
      [keys (mkLuaInline dispatcherLua)]
      ++ lib.optional (flags != null) flags;
  };
in {
  wayland.windowManager.hyprland.settings.bind = [
    # APPLICATIONS
    (bind "SUPER + Return" (exec "kitty") null)
    (bind "SUPER + B" (exec "google-chrome-stable") null)
    (bind "SUPER + E" (exec "nemo") null)
    (bind "SUPER + Space" (noctalia "launcher toggle") null)
    (bind "SUPER + D" (noctalia "launcher toggle") null)
    (bind "SUPER + M" (exec "kitty -e btop") null)
    (bind "CTRL + SHIFT + Escape" (exec "kitty -e btop") null)
    (bind "SUPER + Comma" (noctalia "settings toggle") null)
    (bind "SUPER + SHIFT + D" (exec "discord") null)

    # MOUSE BINDS
    (bind "SUPER + mouse:272" "hl.dsp.window.drag()" {mouse = true;})
    (bind "SUPER + mouse:273" "hl.dsp.window.resize()" {mouse = true;})

    # Horizontal wheel scrolls the tape by a column — same gesture as niri's
    # wheel-over-gap scroll, mapped to the dedicated horizontal wheel instead
    # of the vertical one (which is used for workspace switching below).
    (bind "SUPER + mouse_right" ''hl.dsp.layout("move +col")'' null)
    (bind "SUPER + mouse_left" ''hl.dsp.layout("move -col")'' null)

    # Vertical wheel switches workspaces.
    (bind "SUPER + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'' null)
    (bind "SUPER + mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'' null)

    # WINDOW MANAGEMENT
    (bind "SUPER + Q" "hl.dsp.window.close()" null)
    (bind "SUPER + F" ''hl.dsp.window.fullscreen({ mode = "maximized" })'' null)
    (bind "SUPER + SHIFT + F" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'' null)
    (bind "SUPER + SHIFT + Space" ''hl.dsp.window.float({ action = "toggle" })'' null)

    # SYSTEM CONTROLS
    (bind "SUPER + Escape" (noctalia "lockScreen lock") null)
    (bind "SUPER + SHIFT + Escape" (noctalia "sessionMenu toggle") null)
    (bind "SUPER + N" (noctalia "notifications toggleHistory") null)
    (bind "SUPER + T" (noctalia "darkMode toggle") null)
    (bind "SUPER + SHIFT + N" (noctalia "nightLight toggle") null)

    # THEMING & CUSTOMIZATION
    (bind "SUPER + C" (noctalia "colorPicker toggle") null)
    (bind "SUPER + W" (noctalia "desktopWidgets toggle") null)

    # SCREENSHOTS — no native dispatcher in Hyprland, using grimblast
    (bind "Print" (exec ''grimblast --notify copysave area ~/Pictures/Screenshots/Screenshot-$(date +%Y-%m-%d-%H%M%S).png'') null)
    (bind "SUPER + Print" (exec ''grimblast --notify copysave screen ~/Pictures/Screenshots/Screenshot-$(date +%Y-%m-%d-%H%M%S).png'') null)

    # FOCUS CONTROL
    (bind "ALT + Tab" ''hl.dsp.focus({ last = true })'' null)

    # Arrow Keys
    (bind "SUPER + left" ''hl.dsp.focus({ direction = "l" })'' null)
    (bind "SUPER + right" ''hl.dsp.focus({ direction = "r" })'' null)
    (bind "SUPER + up" ''hl.dsp.focus({ direction = "u" })'' null)
    (bind "SUPER + down" ''hl.dsp.focus({ direction = "d" })'' null)

    # Vim Keys
    (bind "SUPER + H" ''hl.dsp.focus({ direction = "l" })'' null)
    (bind "SUPER + L" ''hl.dsp.focus({ direction = "r" })'' null)
    (bind "SUPER + K" ''hl.dsp.focus({ direction = "u" })'' null)
    (bind "SUPER + J" ''hl.dsp.focus({ direction = "d" })'' null)

    # MOVE WINDOW
    (bind "SUPER + CTRL + left" ''hl.dsp.window.move({ direction = "l" })'' null)
    (bind "SUPER + CTRL + right" ''hl.dsp.window.move({ direction = "r" })'' null)
    (bind "SUPER + CTRL + up" ''hl.dsp.window.move({ direction = "u" })'' null)
    (bind "SUPER + CTRL + down" ''hl.dsp.window.move({ direction = "d" })'' null)

    (bind "SUPER + CTRL + H" ''hl.dsp.window.move({ direction = "l" })'' null)
    (bind "SUPER + CTRL + L" ''hl.dsp.window.move({ direction = "r" })'' null)
    (bind "SUPER + CTRL + K" ''hl.dsp.window.move({ direction = "u" })'' null)
    (bind "SUPER + CTRL + J" ''hl.dsp.window.move({ direction = "d" })'' null)

    # MONITOR FOCUS
    (bind "SUPER + SHIFT + left" ''hl.dsp.focus({ monitor = "l" })'' null)
    (bind "SUPER + SHIFT + right" ''hl.dsp.focus({ monitor = "r" })'' null)
    (bind "SUPER + SHIFT + up" ''hl.dsp.focus({ monitor = "u" })'' null)
    (bind "SUPER + SHIFT + down" ''hl.dsp.focus({ monitor = "d" })'' null)

    (bind "SUPER + SHIFT + H" ''hl.dsp.focus({ monitor = "l" })'' null)
    (bind "SUPER + SHIFT + L" ''hl.dsp.focus({ monitor = "r" })'' null)
    (bind "SUPER + SHIFT + K" ''hl.dsp.focus({ monitor = "u" })'' null)
    (bind "SUPER + SHIFT + J" ''hl.dsp.focus({ monitor = "d" })'' null)

    # MOVE WINDOW TO MONITOR
    (bind "SUPER + SHIFT + CTRL + left" ''hl.dsp.window.move({ monitor = "l" })'' null)
    (bind "SUPER + SHIFT + CTRL + right" ''hl.dsp.window.move({ monitor = "r" })'' null)
    (bind "SUPER + SHIFT + CTRL + up" ''hl.dsp.window.move({ monitor = "u" })'' null)
    (bind "SUPER + SHIFT + CTRL + down" ''hl.dsp.window.move({ monitor = "d" })'' null)

    (bind "SUPER + SHIFT + CTRL + H" ''hl.dsp.window.move({ monitor = "l" })'' null)
    (bind "SUPER + SHIFT + CTRL + L" ''hl.dsp.window.move({ monitor = "r" })'' null)
    (bind "SUPER + SHIFT + CTRL + K" ''hl.dsp.window.move({ monitor = "u" })'' null)
    (bind "SUPER + SHIFT + CTRL + J" ''hl.dsp.window.move({ monitor = "d" })'' null)

    # WORKSPACES
    (bind "SUPER + 1" ''hl.dsp.focus({ workspace = 1 })'' null)
    (bind "SUPER + 2" ''hl.dsp.focus({ workspace = 2 })'' null)
    (bind "SUPER + 3" ''hl.dsp.focus({ workspace = 3 })'' null)
    (bind "SUPER + 4" ''hl.dsp.focus({ workspace = 4 })'' null)
    (bind "SUPER + 5" ''hl.dsp.focus({ workspace = 5 })'' null)
    (bind "SUPER + 6" ''hl.dsp.focus({ workspace = 6 })'' null)
    (bind "SUPER + 7" ''hl.dsp.focus({ workspace = 7 })'' null)
    (bind "SUPER + 8" ''hl.dsp.focus({ workspace = 8 })'' null)
    (bind "SUPER + 9" ''hl.dsp.focus({ workspace = 9 })'' null)

    (bind "SUPER + CTRL + Page_Down" ''hl.dsp.window.move({ workspace = "+1" })'' null)
    (bind "SUPER + CTRL + Page_Up" ''hl.dsp.window.move({ workspace = "-1" })'' null)

    (bind "SUPER + Page_Down" ''hl.dsp.focus({ workspace = "+1" })'' null)
    (bind "SUPER + Page_Up" ''hl.dsp.focus({ workspace = "-1" })'' null)

    # COLUMN OPERATIONS (native scrolling layout — same model as niri)
    (bind "SUPER + bracketleft" ''hl.dsp.layout("consume_or_expel prev")'' null)
    (bind "SUPER + bracketright" ''hl.dsp.layout("consume_or_expel next")'' null)
    (bind "SUPER + R" ''hl.dsp.layout("colresize +conf")'' null)
    # No direct "center column" dispatcher; "fit active" brings the focused
    # column fully into view, closest equivalent to niri's center-column.
    (bind "SUPER + SHIFT + C" ''hl.dsp.layout("fit active")'' null)

    # Scroll the tape by a whole column, without moving focus.
    (bind "SUPER + CTRL + bracketleft" ''hl.dsp.layout("move -col")'' null)
    (bind "SUPER + CTRL + bracketright" ''hl.dsp.layout("move +col")'' null)

    # Swap the focused column with its left/right neighbor.
    (bind "SUPER + SHIFT + bracketleft" ''hl.dsp.layout("swapcol l")'' null)
    (bind "SUPER + SHIFT + bracketright" ''hl.dsp.layout("swapcol r")'' null)

    # Move focused window to its own new column.
    (bind "SUPER + P" ''hl.dsp.layout("promote")'' null)

    # Explicit expel (into its own column) / consume (into previous column) —
    # consume_or_expel above picks one of these automatically based on state.
    (bind "SUPER + O" ''hl.dsp.layout("expel")'' null)
    (bind "SUPER + SHIFT + O" ''hl.dsp.layout("consume")'' null)

    # Expand focused window into remaining free space on the monitor.
    (bind "SUPER + SHIFT + Return" ''hl.dsp.layout("fit expand")'' null)

    # Fully scroll the focused column into view.
    (bind "SUPER + CTRL + C" ''hl.dsp.layout("fit_into_view")'' null)

    # Toggle scroll-follow-focus off/on for the current workspace.
    (bind "SUPER + SHIFT + I" ''hl.dsp.layout("inhibit_scroll")'' null)

    # RESIZE
    # Column width (scrolling layout) — relative fraction step, same model as
    # niri's set-column-width "-10%"/"+10%".
    (bind "SUPER + Minus" ''hl.dsp.layout("colresize -0.1")'' null)
    (bind "SUPER + Equal" ''hl.dsp.layout("colresize +0.1")'' null)

    # Window height — Lua resize dispatcher takes pixel deltas, not the
    # percentage-of-window-size form classic hyprlang had.
    (bind "SUPER + SHIFT + Minus" ''hl.dsp.window.resize({ x = 0, y = -100, relative = true })'' null)
    (bind "SUPER + SHIFT + Equal" ''hl.dsp.window.resize({ x = 0, y = 100, relative = true })'' null)

    # CLIPBOARD
    (bind "SUPER + V" (noctalia "launcher clipboard") null)

    # SYSTEM
    # NOT hl.dsp.exit() — under UWSM this bypasses graceful shutdown of the
    # login session bound to it. See
    # https://wiki.hypr.land/Useful-Utilities/Systemd-start/#uwsm
    (bind "SUPER + SHIFT + E" (exec "uwsm stop") null)
    (bind "SUPER + SHIFT + P" ''hl.dsp.dpms({ action = "off" })'' null)

    # MEDIA CONTROLS
    (bind "XF86AudioPlay" (exec "playerctl play-pause") null)
    (bind "XF86AudioNext" (exec "playerctl next") null)
    (bind "XF86AudioPrev" (exec "playerctl previous") null)
    (bind "XF86AudioStop" (exec "playerctl stop") null)
    (bind "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") null)
    (bind "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") null)

    # Repeat while held (classic "binde")
    (bind "XF86AudioRaiseVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") {repeating = true;})
    (bind "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") {repeating = true;})
    (bind "XF86MonBrightnessUp" (exec "brightnessctl set 5%+") {repeating = true;})
    (bind "XF86MonBrightnessDown" (exec "brightnessctl set 5%-") {repeating = true;})
  ];
}
