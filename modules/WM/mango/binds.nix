_: let
  # "MODS,KEY" string (mango's own comma-separated bind grammar, not
  # Hyprland/niri's). dispatcher + args are appended as extra comma fields.
  # See https://mangowm.github.io/docs/nix-options (settings.bind) and
  # https://github.com/DreamMaoMao/mango-config/blob/main/bind.conf for the
  # real dispatcher names (no exhaustive dispatcher reference page exists).
  bind = keys: dispatcher: args:
    "${keys},${dispatcher}"
    + (
      if args == ""
      then ""
      else ",${args}"
    );

  noctalia = cmd: "spawn,noctalia msg ${cmd}";
in {
  wayland.windowManager.mango.settings = {
    bind = [
      # ============================================
      # APPLICATIONS
      # ============================================
      (bind "SUPER,Return" "spawn" "kitty")
      (bind "SUPER,B" "spawn" "google-chrome-stable")
      (bind "SUPER,E" "spawn" "nemo")
      (bind "SUPER,Space" (noctalia "panel-toggle launcher") "")
      (bind "SUPER,D" (noctalia "panel-toggle launcher") "")
      (bind "SUPER,M" "spawn" "kitty -e btop")
      (bind "CTRL+SHIFT,Escape" "spawn" "kitty -e btop")
      (bind "SUPER,Comma" (noctalia "settings-toggle") "")
      (bind "SUPER+SHIFT,D" "spawn" "discord")

      # ============================================
      # WINDOW MANAGEMENT
      # ============================================
      (bind "ALT,Q" "killclient" "")
      (bind "SUPER,F" "togglemaximizescreen" "")
      (bind "SUPER+SHIFT,F" "togglefullscreen" "")
      (bind "SUPER+SHIFT,Space" "togglefloating" "")

      # ============================================
      # SYSTEM CONTROLS
      # ============================================
      (bind "SUPER,Escape" (noctalia "session lock") "")
      (bind "SUPER+SHIFT,Escape" (noctalia "panel-toggle session") "")
      (bind "SUPER,N" (noctalia "panel-toggle control-center notifications") "")
      (bind "SUPER,T" (noctalia "theme-mode-toggle") "")
      (bind "SUPER+SHIFT,N" (noctalia "nightlight-toggle") "")

      # ============================================
      # THEMING & CUSTOMIZATION
      # ============================================
      # Mod+C (colorPicker toggle) dropped: v5 has no standalone color-picker
      # panel/IPC command — the picker is now an internal dialog reached only
      # from Settings/wallpaper UI, not exposed for direct binding.
      (bind "SUPER,W" (noctalia "desktop-widgets-toggle") "")

      # ============================================
      # SCREENSHOTS
      # ============================================
      (bind "none,Print" "spawn_shell" ''grim -g "$(slurp)" - | satty -f -'')
      (bind "SUPER,Print" "spawn_shell" ''grim - | satty -f -'')

      # ============================================
      # FOCUS CONTROL
      # ============================================
      (bind "ALT,Tab" "focuslast" "")

      # Arrow keys
      (bind "SUPER,Left" "focusdir" "left")
      (bind "SUPER,Right" "focusdir" "right")
      (bind "SUPER,Up" "focusdir" "up")
      (bind "SUPER,Down" "focusdir" "down")

      # Vim keys
      (bind "SUPER,H" "focusdir" "left")
      (bind "SUPER,L" "focusdir" "right")
      (bind "SUPER,K" "focusdir" "up")
      (bind "SUPER,J" "focusdir" "down")

      # ============================================
      # MOVE WINDOW (swap with neighbor — mango has no "move to column",
      # only exchange_client, since it isn't a scrolling-tape-native model)
      # ============================================
      (bind "SUPER+CTRL,Left" "exchange_client" "left")
      (bind "SUPER+CTRL,Right" "exchange_client" "right")
      (bind "SUPER+CTRL,Up" "exchange_client" "up")
      (bind "SUPER+CTRL,Down" "exchange_client" "down")

      (bind "SUPER+CTRL,H" "exchange_client" "left")
      (bind "SUPER+CTRL,L" "exchange_client" "right")
      (bind "SUPER+CTRL,K" "exchange_client" "up")
      (bind "SUPER+CTRL,J" "exchange_client" "down")

      # ============================================
      # MONITOR FOCUS / MOVE WINDOW TO MONITOR
      # ============================================
      (bind "SUPER+SHIFT,Left" "focusmon" "left")
      (bind "SUPER+SHIFT,Right" "focusmon" "right")
      (bind "SUPER+SHIFT,Up" "focusmon" "up")
      (bind "SUPER+SHIFT,Down" "focusmon" "down")

      (bind "SUPER+SHIFT+CTRL,Left" "tagmon" "left")
      (bind "SUPER+SHIFT+CTRL,Right" "tagmon" "right")
      (bind "SUPER+SHIFT+CTRL,Up" "tagmon" "up")
      (bind "SUPER+SHIFT+CTRL,Down" "tagmon" "down")

      # ============================================
      # TAGS (mango's workspace equivalent)
      # ============================================
      (bind "SUPER,1" "view" "1,0")
      (bind "SUPER,2" "view" "2,0")
      (bind "SUPER,3" "view" "3,0")
      (bind "SUPER,4" "view" "4,0")
      (bind "SUPER,5" "view" "5,0")
      (bind "SUPER,6" "view" "6,0")
      (bind "SUPER,7" "view" "7,0")
      (bind "SUPER,8" "view" "8,0")
      (bind "SUPER,9" "view" "9,0")

      (bind "SUPER+CTRL,1" "tag" "1,0")
      (bind "SUPER+CTRL,2" "tag" "2,0")
      (bind "SUPER+CTRL,3" "tag" "3,0")
      (bind "SUPER+CTRL,4" "tag" "4,0")
      (bind "SUPER+CTRL,5" "tag" "5,0")
      (bind "SUPER+CTRL,6" "tag" "6,0")
      (bind "SUPER+CTRL,7" "tag" "7,0")
      (bind "SUPER+CTRL,8" "tag" "8,0")
      (bind "SUPER+CTRL,9" "tag" "9,0")

      (bind "SUPER,Page_Down" "viewtoright" "0")
      (bind "SUPER,Page_Up" "viewtoleft" "0")
      (bind "SUPER+CTRL,Page_Down" "tagtoright" "0")
      (bind "SUPER+CTRL,Page_Up" "tagtoleft" "0")

      # ============================================
      # SCROLLER LAYOUT
      # ============================================
      (bind "SUPER,bracketleft" "switch_proportion_preset" "prev")
      (bind "SUPER,bracketright" "switch_proportion_preset" "")
      (bind "SUPER+SHIFT,R" "set_proportion" "1.0")

      # ============================================
      # CONFIG RELOAD (hot-reload, no compositor restart needed)
      # ============================================
      (bind "SUPER,R" "reload_config" "")

      # ============================================
      # RESIZE
      # ============================================
      (bind "SUPER,Minus" "scroller_stack" "left")
      (bind "SUPER,Equal" "scroller_stack" "right")
      (bind "SUPER+SHIFT,Minus" "resizewin" "+0,-100")
      (bind "SUPER+SHIFT,Equal" "resizewin" "+0,+100")

      # ============================================
      # CLIPBOARD
      # ============================================
      (bind "SUPER,V" (noctalia "panel-toggle clipboard") "")

      # ============================================
      # SYSTEM
      # ============================================
      (bind "SUPER+SHIFT,E" "quit" "")

      # ============================================
      # MEDIA CONTROLS
      # ============================================
      (bind "none,XF86AudioPlay" "spawn" "playerctl play-pause")
      (bind "none,XF86AudioNext" "spawn" "playerctl next")
      (bind "none,XF86AudioPrev" "spawn" "playerctl previous")
      (bind "none,XF86AudioStop" "spawn" "playerctl stop")
      (bind "none,XF86AudioMute" "spawn" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
      (bind "none,XF86AudioMicMute" "spawn" "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
      (bind "none,XF86AudioRaiseVolume" "spawn" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
      (bind "none,XF86AudioLowerVolume" "spawn" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
      (bind "none,XF86MonBrightnessUp" "spawn" "brightnessctl set 5%+")
      (bind "none,XF86MonBrightnessDown" "spawn" "brightnessctl set 5%-")
    ];

    mousebind = [
      "SUPER,btn_left,moveresize,curmove"
      "SUPER,btn_right,moveresize,curresize"
    ];
  };
}
