_: let
  noctalia = cmd: "noctalia-shell ipc call ${cmd}";
in {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # ============================================
      # APPLICATIONS
      # ============================================

      "$mod, Return, exec, kitty"
      "$mod, B, exec, google-chrome-stable"
      "$mod, E, exec, nemo"
      "$mod, Space, exec, ${noctalia "launcher toggle"}"
      "$mod, D, exec, ${noctalia "launcher toggle"}"
      "$mod, M, exec, kitty -e btop"
      "CTRL SHIFT, Escape, exec, kitty -e btop"
      "$mod, Comma, exec, ${noctalia "settings toggle"}"
      "$mod SHIFT, D, exec, discord"

      # ============================================
      # WINDOW MANAGEMENT
      # ============================================

      "$mod, Q, killactive"
      # niri's maximize-column fills the column but keeps other columns visible;
      # Hyprland has no scrolling columns, so this maps to "maximize" (fill
      # workspace, keep gaps) rather than true fullscreen.
      "$mod, F, fullscreen, 1"
      "$mod SHIFT, F, fullscreen, 0"
      "$mod SHIFT, Space, togglefloating"

      # ============================================
      # SYSTEM CONTROLS
      # ============================================

      "$mod, Escape, exec, ${noctalia "lockScreen lock"}"
      "$mod SHIFT, Escape, exec, ${noctalia "sessionMenu toggle"}"
      "$mod, N, exec, ${noctalia "notifications toggleHistory"}"
      "$mod, T, exec, ${noctalia "darkMode toggle"}"
      "$mod SHIFT, N, exec, ${noctalia "nightLight toggle"}"

      # ============================================
      # THEMING & CUSTOMIZATION
      # ============================================

      "$mod, C, exec, ${noctalia "colorPicker toggle"}"
      "$mod, W, exec, ${noctalia "desktopWidgets toggle"}"

      # ============================================
      # SCREENSHOTS — no native dispatcher in Hyprland, using grimblast
      # ============================================

      ", Print, exec, grimblast --notify copysave area ~/Pictures/Screenshots/Screenshot-$(date +%Y-%m-%d-%H%M%S).png"
      "$mod, Print, exec, grimblast --notify copysave screen ~/Pictures/Screenshots/Screenshot-$(date +%Y-%m-%d-%H%M%S).png"

      # ============================================
      # FOCUS CONTROL
      # ============================================

      "ALT, Tab, focuscurrentorlast"

      # Arrow Keys
      "$mod, Left, movefocus, l"
      "$mod, Right, movefocus, r"
      "$mod, Up, movefocus, u"
      "$mod, Down, movefocus, d"

      # Vim Keys
      "$mod, H, movefocus, l"
      "$mod, L, movefocus, r"
      "$mod, K, movefocus, u"
      "$mod, J, movefocus, d"

      # ============================================
      # MOVE WINDOW
      # ============================================

      "$mod CTRL, Left, movewindow, l"
      "$mod CTRL, Right, movewindow, r"
      "$mod CTRL, Up, movewindow, u"
      "$mod CTRL, Down, movewindow, d"

      "$mod CTRL, H, movewindow, l"
      "$mod CTRL, L, movewindow, r"
      "$mod CTRL, K, movewindow, u"
      "$mod CTRL, J, movewindow, d"

      # ============================================
      # MONITOR FOCUS
      # ============================================

      "$mod SHIFT, Left, focusmonitor, l"
      "$mod SHIFT, Right, focusmonitor, r"
      "$mod SHIFT, Up, focusmonitor, u"
      "$mod SHIFT, Down, focusmonitor, d"

      "$mod SHIFT, H, focusmonitor, l"
      "$mod SHIFT, L, focusmonitor, r"
      "$mod SHIFT, K, focusmonitor, u"
      "$mod SHIFT, J, focusmonitor, d"

      # ============================================
      # MOVE WINDOW TO MONITOR
      # ============================================

      "$mod SHIFT CTRL, Left, movewindow, mon:l"
      "$mod SHIFT CTRL, Right, movewindow, mon:r"
      "$mod SHIFT CTRL, Up, movewindow, mon:u"
      "$mod SHIFT CTRL, Down, movewindow, mon:d"

      "$mod SHIFT CTRL, H, movewindow, mon:l"
      "$mod SHIFT CTRL, L, movewindow, mon:r"
      "$mod SHIFT CTRL, K, movewindow, mon:u"
      "$mod SHIFT CTRL, J, movewindow, mon:d"

      # ============================================
      # WORKSPACES
      # ============================================

      "$mod, 1, workspace, 1"
      "$mod, 2, workspace, 2"
      "$mod, 3, workspace, 3"
      "$mod, 4, workspace, 4"
      "$mod, 5, workspace, 5"
      "$mod, 6, workspace, 6"
      "$mod, 7, workspace, 7"
      "$mod, 8, workspace, 8"
      "$mod, 9, workspace, 9"

      "$mod CTRL, Page_Down, movetoworkspace, +1"
      "$mod CTRL, Page_Up, movetoworkspace, -1"

      "$mod, Page_Down, workspace, +1"
      "$mod, Page_Up, workspace, -1"

      # ============================================
      # RESIZE
      # ============================================

      "$mod, Minus, resizeactive, -10% 0"
      "$mod, Equal, resizeactive, +10% 0"
      "$mod SHIFT, Minus, resizeactive, 0 -10%"
      "$mod SHIFT, Equal, resizeactive, 0 +10%"

      # ============================================
      # CLIPBOARD
      # ============================================

      "$mod, V, exec, ${noctalia "launcher clipboard"}"

      # ============================================
      # SYSTEM
      # ============================================

      "$mod SHIFT, E, exit"
      "$mod SHIFT, P, dpms, off"

      # ============================================
      # MEDIA CONTROLS
      # ============================================

      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
      ", XF86AudioStop, exec, playerctl stop"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
    ];

    binde = [
      # ============================================
      # MEDIA CONTROLS (repeat while held)
      # ============================================

      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
    ];
  };
}
