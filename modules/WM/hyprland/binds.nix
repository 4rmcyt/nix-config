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

      # File Manager
      "$mod, E, exec, dolphin"
      "ALT, E, exec, hyprctl dispatch exec '[float; size 1111 700] dolphin'"

      # Launcher
      "$mod, D, exec, walker"

      # System Monitor
      "CTRL SHIFT, Escape, exec, missioncenter"

      # Communication
      "$mod SHIFT, D, exec, webcord --enable-features=UseOzonePlatform --ozone-platform=wayland"

      # Audio
      "$mod SHIFT, S, exec, SoundWireServer"

      # ============================================
      # WINDOW MANAGEMENT
      # ============================================

      # Close
      "$mod, Q, killactive,"

      # Fullscreen
      "$mod, F, fullscreen, 0"
      "$mod SHIFT, F, fullscreen, 1"

      # Floating
      "$mod, Space, togglefloating,"
      "ALT, Space, togglefloating,"

      # Layout
      "$mod, P, pseudo,"
      "$mod, X, togglesplit,"

      # ============================================
      # SYSTEM CONTROLS
      # ============================================

      # Lock Screen
      "$mod, Escape, exec, swaylock"
      "ALT, Escape, exec, hyprlock"

      # Power Menu
      "$mod SHIFT, Escape, exec, power-menu"

      # Waybar Toggle
      "$mod SHIFT, B, exec, toggle-waybar"

      # Notifications
      "$mod, N, exec, swaync-client -t -sw"

      # ============================================
      # THEMING & CUSTOMIZATION
      # ============================================

      # Color Picker
      "$mod, C ,exec, hyprpicker -a"

      # Wallpaper
      "$mod, W, exec, waypaper"
      "$mod SHIFT, W, exec, hyprctl dispatch exec '[float; size 925 615] waypaper'"

      # ============================================
      # SCREENSHOTS
      # ============================================
      ",Print, exec, grimblast copy area"
      "$mod, Print, exec, grimblast save area"
      "$mod SHIFT, Print, exec, grimblast copy area && swappy -f - -o -"

      # ============================================
      # FOCUS CONTROL
      # ============================================

      # Alt+Tab window switching with Walker
      "ALT, Tab, exec, walker --modules applications"

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
      # MEDIA CONTROLS
      # ============================================
      ",XF86AudioPlay,exec, playerctl play-pause"
      ",XF86AudioNext,exec, playerctl next"
      ",XF86AudioPrev,exec, playerctl previous"
      ",XF86AudioStop,exec, playerctl stop"

      # ============================================
      # CLIPBOARD
      # ============================================
      "$mod, V, exec, cliphist list | head -50 | walker --dmenu | cliphist decode | wl-copy"
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
