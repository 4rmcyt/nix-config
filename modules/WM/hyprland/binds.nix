_: {
  wayland.windowManager.hyprland.settings = {
    binds = {
      movefocus_cycles_fullscreen = true;
    };

    bind = [
      # ============================================
      # APPLICATIONS
      # ============================================

      # Terminal
      "$mod, Return, exec, wezterm start --cwd ."
      "ALT, Return, exec, [float; size 1111 700] wezterm start --cwd ."
      "$mod SHIFT, Return, exec, [fullscreen] wezterm start --cwd ."

      # Browser
      "$mod, B, exec, chromium"

      # File Manager (GNOME Nautilus - best DMS integration)
      "$mod, E, exec, nautilus"
      "ALT, E, exec, hyprctl dispatch exec '[float; size 1111 700] nautilus'"

      # DMS Application Launcher (Primary)
      "$mod, Space, exec, quickshell -m dms.overview"

      # Walker Fallback Launcher
      "$mod, D, exec, walker"

      # System Monitor (Use DMS Task Manager)
      "CTRL SHIFT, Escape, exec, quickshell -m dms.taskmgr"

      # DMS Task Manager
      "$mod, M, exec, quickshell -m dms.taskmgr"

      # DMS Settings
      "$mod, comma, exec, quickshell -m dms.settings"

      # Communication
      "$mod SHIFT, D, exec, discord --enable-features=UseOzonePlatform --ozone-platform=wayland"

      # ============================================
      # WINDOW MANAGEMENT
      # ============================================

      # Close
      "$mod, Q, killactive,"

      # Fullscreen
      "$mod, F, fullscreen, 0"
      "$mod SHIFT, F, fullscreen, 1"

      # Floating (moved from Super+Space to avoid conflict with DMS launcher)
      "$mod SHIFT, Space, togglefloating,"

      # Layout
      "$mod, P, pseudo,"
      "$mod, X, togglesplit,"

      # ============================================
      # SYSTEM CONTROLS
      # ============================================

      # Lock Screen (DMS recommended: swaylock)
      "$mod, Escape, exec, swaylock"

      # Power Menu (DMS)
      "$mod SHIFT, Escape, exec, dms ipc call modal toggle power-menu"

      # Notifications (DMS)
      "$mod, N, exec, dms ipc call modal toggle notifications"

      # Keybinds Cheatsheet
      "$mod, slash, exec, dms ipc call keybinds toggle hyprland"

      # Toggle Theme (Light/Dark)
      "$mod, T, exec, dms ipc call appearance toggle-theme"

      # Toggle Night Mode
      "$mod SHIFT, N, exec, dms ipc call night-mode toggle"

      # ============================================
      # THEMING & CUSTOMIZATION
      # ============================================

      # Color Picker (DMS)
      "$mod, C, exec, dms ipc call modal toggle color-picker"

      # DMS Wallpaper Selector (Media Hub/DankDash)
      "$mod, W, exec, dms ipc call modal toggle dashboard"

      # ============================================
      # SCREENSHOTS - DMS CLI
      # ============================================

      # Region selection (default)
      ",Print, exec, dms screenshot"

      # Full screen of active display
      "$mod, Print, exec, dms screenshot full"

      # All displays combined
      "$mod SHIFT, Print, exec, dms screenshot all"

      # Clipboard only (no file)
      "CTRL, Print, exec, dms screenshot --no-file"

      # ============================================
      # FOCUS CONTROL
      # ============================================

      # Alt+Tab window switching with DMS
      "ALT, Tab, exec, quickshell -m dms.alttab"

      # Arrow Keys
      "$mod, left,  movefocus, l"
      "$mod, right, movefocus, r"
      "$mod, up,    movefocus, u"
      "$mod, down,  movefocus, d"

      # Vim Keys
      "$mod, h, movefocus, l"
      "$mod, j, movefocus, d"
      "$mod, k, movefocus, u"
      "$mod, l, movefocus, r"

      # Z-Order (Arrow Keys)
      "$mod, left,  alterzorder, top"
      "$mod, right, alterzorder, top"
      "$mod, up,    alterzorder, top"
      "$mod, down,  alterzorder, top"

      # Z-Order (Vim Keys)
      "$mod, h, alterzorder, top"
      "$mod, j, alterzorder, top"
      "$mod, k, alterzorder, top"
      "$mod, l, alterzorder, top"

      # Focus Floating/Tiled
      "CTRL ALT, up, exec, hyprctl dispatch focuswindow floating"
      "CTRL ALT, down, exec, hyprctl dispatch focuswindow tiled"

      # ============================================
      # MOVE WINDOW
      # ============================================

      # Arrow Keys
      "$mod SHIFT, left, movewindow, l"
      "$mod SHIFT, right, movewindow, r"
      "$mod SHIFT, up, movewindow, u"
      "$mod SHIFT, down, movewindow, d"

      # Vim Keys
      "$mod SHIFT, h, movewindow, l"
      "$mod SHIFT, j, movewindow, d"
      "$mod SHIFT, k, movewindow, u"
      "$mod SHIFT, l, movewindow, r"

      # ============================================
      # RESIZE WINDOW
      # ============================================

      # Arrow Keys
      "$mod CTRL, left, resizeactive, -80 0"
      "$mod CTRL, right, resizeactive, 80 0"
      "$mod CTRL, up, resizeactive, 0 -80"
      "$mod CTRL, down, resizeactive, 0 80"

      # Vim Keys
      "$mod CTRL, h, resizeactive, -80 0"
      "$mod CTRL, j, resizeactive, 0 80"
      "$mod CTRL, k, resizeactive, 0 -80"
      "$mod CTRL, l, resizeactive, 80 0"

      # ============================================
      # MOVE WINDOW (FLOATING)
      # ============================================

      # Arrow Keys
      "$mod ALT, left, moveactive,  -80 0"
      "$mod ALT, right, moveactive, 80 0"
      "$mod ALT, up, moveactive, 0 -80"
      "$mod ALT, down, moveactive, 0 80"

      # Vim Keys
      "$mod ALT, h, moveactive,  -80 0"
      "$mod ALT, j, moveactive, 0 80"
      "$mod ALT, k, moveactive, 0 -80"
      "$mod ALT, l, moveactive, 80 0"

      # ============================================
      # MEDIA CONTROLS - DMS IPC
      # ============================================

      # Media playback
      ",XF86AudioPlay, exec, dms ipc call media play-pause"
      ",XF86AudioNext, exec, dms ipc call media next"
      ",XF86AudioPrev, exec, dms ipc call media previous"
      ",XF86AudioStop, exec, dms ipc call media stop"

      # Volume controls
      ",XF86AudioRaiseVolume, exec, dms ipc call audio volume-increment 5"
      ",XF86AudioLowerVolume, exec, dms ipc call audio volume-decrement 5"
      ",XF86AudioMute, exec, dms ipc call audio volume-toggle-mute"

      # Brightness controls (with OSD)
      ",XF86MonBrightnessUp, exec, dms ipc call brightness increment 5"
      ",XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5"

      # ============================================
      # CLIPBOARD - DMS Integration
      # ============================================

      # DMS Clipboard history
      "$mod, V, exec, dms ipc call modal toggle clipboard"

      # Alternative: Walker with cliphist
      "$mod SHIFT, V, exec, cliphist list | head -50 | walker --dmenu | cliphist decode | wl-copy"
    ];

    # ============================================
    # MOUSE BINDINGS
    # ============================================
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
  };
}
