_: {
  programs.niri.settings = {
    binds = {
      # ============================================
      # APPLICATIONS
      # ============================================

      # Terminal
      "Super+Return" = {
        action = "spawn";
        command = "wezterm start --cwd .";
      };
      "Alt+Return" = {
        action = "spawn";
        command = "wezterm start --cwd .";
      };
      "Super+Shift+Return" = {
        action = "spawn";
        command = "wezterm start --cwd .";
      };

      # Browser
      "Super+B" = {
        action = "spawn";
        command = "chromium";
      };

      # File Manager
      "Super+E" = {
        action = "spawn";
        command = "dolphin";
      };
      "Alt+E" = {
        action = "spawn";
        command = "dolphin";
      };

      # Launcher
      "Super+D" = {
        action = "spawn";
        command = "walker";
      };

      # System Monitor
      "Ctrl+Shift+Escape" = {
        action = "spawn";
        command = "missioncenter";
      };

      # Communication
      "Super+Shift+D" = {
        action = "spawn";
        command = "webcord --enable-features=UseOzonePlatform --ozone-platform=wayland";
      };

      # Audio
      "Super+Shift+S" = {
        action = "spawn";
        command = "SoundWireServer";
      };

      # ============================================
      # WINDOW MANAGEMENT
      # ============================================

      # Close
      "Super+Q" = {
        action = "close-window";
      };

      # Fullscreen
      "Super+F" = {
        action = "set-fullscreen";
        value = false;
      };
      "Super+Shift+F" = {
        action = "set-fullscreen";
        value = true;
      };

      # Floating
      "Super+Space" = {
        action = "toggle-floating";
      };
      "Alt+Space" = {
        action = "toggle-floating";
      };

      # ============================================
      # SYSTEM CONTROLS
      # ============================================

      # Lock Screen
      "Super+Escape" = {
        action = "spawn";
        command = "swaylock";
      };
      "Alt+Escape" = {
        action = "spawn";
        command = "hyprlock";
      };

      # Power Menu
      "Super+Shift+Escape" = {
        action = "spawn";
        command = "power-menu";
      };

      # Notifications
      "Super+N" = {
        action = "spawn";
        command = "swaync-client -t -sw";
      };

      # ============================================
      # THEMING & CUSTOMIZATION
      # ============================================

      # Color Picker
      "Super+C" = {
        action = "spawn";
        command = "hyprpicker -a";
      };

      # Wallpaper
      "Super+W" = {
        action = "spawn";
        command = "waypaper";
      };
      "Super+Shift+W" = {
        action = "spawn";
        command = "waypaper";
      };

      # ============================================
      # SCREENSHOTS
      # ============================================
      "Print" = {
        action = "spawn";
        command = "grimblast copy area";
      };
      "Super+Print" = {
        action = "spawn";
        command = "grimblast save area";
      };
      "Super+Shift+Print" = {
        action = "spawn";
        command = "grimblast copy area && swappy -f - -o -";
      };

      # ============================================
      # FOCUS CONTROL
      # ============================================

      # Alt+Tab window switching with Walker
      "Alt+Tab" = {
        action = "spawn";
        command = "walker --modules applications";
      };

      # Arrow Keys - Focus Movement
      "Super+Left" = {
        action = "focus-column-left";
      };
      "Super+Right" = {
        action = "focus-column-right";
      };
      "Super+Up" = {
        action = "focus-window-up";
      };
      "Super+Down" = {
        action = "focus-window-down";
      };

      # Vim Keys - Focus Movement
      "Super+H" = {
        action = "focus-column-left";
      };
      "Super+L" = {
        action = "focus-column-right";
      };
      "Super+K" = {
        action = "focus-window-up";
      };
      "Super+J" = {
        action = "focus-window-down";
      };

      # ============================================
      # MOVE WINDOW
      # ============================================

      # Arrow Keys
      "Super+Shift+Left" = {
        action = "move-column-left";
      };
      "Super+Shift+Right" = {
        action = "move-column-right";
      };
      "Super+Shift+Up" = {
        action = "move-window-up";
      };
      "Super+Shift+Down" = {
        action = "move-window-down";
      };

      # Vim Keys
      "Super+Shift+H" = {
        action = "move-column-left";
      };
      "Super+Shift+L" = {
        action = "move-column-right";
      };
      "Super+Shift+K" = {
        action = "move-window-up";
      };
      "Super+Shift+J" = {
        action = "move-window-down";
      };

      # ============================================
      # RESIZE WINDOW
      # ============================================

      # Arrow Keys
      "Super+Ctrl+Left" = {
        action = "resize-column-left";
        amount = 80;
      };
      "Super+Ctrl+Right" = {
        action = "resize-column-right";
        amount = 80;
      };
      "Super+Ctrl+Up" = {
        action = "resize-window-up";
        amount = 80;
      };
      "Super+Ctrl+Down" = {
        action = "resize-window-down";
        amount = 80;
      };

      # Vim Keys
      "Super+Ctrl+H" = {
        action = "resize-column-left";
        amount = 80;
      };
      "Super+Ctrl+L" = {
        action = "resize-column-right";
        amount = 80;
      };
      "Super+Ctrl+K" = {
        action = "resize-window-up";
        amount = 80;
      };
      "Super+Ctrl+J" = {
        action = "resize-window-down";
        amount = 80;
      };

      # ============================================
      # MEDIA CONTROLS
      # ============================================
      "XF86AudioPlay" = {
        action = "spawn";
        command = "playerctl play-pause";
      };
      "XF86AudioNext" = {
        action = "spawn";
        command = "playerctl next";
      };
      "XF86AudioPrev" = {
        action = "spawn";
        command = "playerctl previous";
      };
      "XF86AudioStop" = {
        action = "spawn";
        command = "playerctl stop";
      };

      # ============================================
      # CLIPBOARD
      # ============================================
      "Super+V" = {
        action = "spawn";
        command = "cliphist list | head -50 | walker --dmenu | cliphist decode | wl-copy";
      };
    };
  };
}
