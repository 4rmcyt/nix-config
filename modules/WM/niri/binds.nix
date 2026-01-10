_: {
  programs.niri.settings = {
    binds = {
      # ============================================
      # APPLICATIONS
      # ============================================

      # Terminal
      "Mod+T".action.spawn = ["wezterm"];
      # "Alt+Return".action.spawn = ["wezterm" "start" "--cwd" "."];

      # Browser
      "Mod+B".action.spawn = "chromium";

      # DMS Application Launcher (Primary)

      "Mod+D".action.spawn = [
        "quickshell"
        "-m"
        "dms.overview"
      ];

      # System Monitor (Use DMS Task Manager instead)
      "Ctrl+Shift+Escape".action.spawn = [
        "quickshell"
        "-m"
        "dms.taskmgr"
      ];

      # DMS Task Manager
      "Mod+M".action.spawn = [
        "quickshell"
        "-m"
        "dms.taskmgr"
      ];

      # DMS Settings
      "Mod+Comma".action.spawn = [
        "quickshell"
        "-m"
        "dms.settings"
      ];

      # Communication
      "Mod+Shift+D".action.spawn = [
        "discord"
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
      ];

      # ============================================
      # WINDOW MANAGEMENT
      # ============================================

      # Close
      "Mod+Q".action.close-window = {};

      # Fullscreen
      "Mod+F".action.fullscreen-window = {};

      # ============================================
      # SYSTEM CONTROLS
      # ============================================

      # Power Menu (DMS)
      "Mod+Shift+Escape".action.spawn = [
        "dms"
        "ipc"
        "call"
        "modal"
        "toggle"
        "power-menu"
      ];

      # Notifications (DMS)
      "Mod+N".action.spawn = [
        "dms"
        "ipc"
        "call"
        "modal"
        "toggle"
        "notifications"
      ];

      # Keybinds Cheatsheet
      "Mod+Slash".action.spawn = [
        "dms"
        "ipc"
        "call"
        "keybinds"
        "toggle"
        "niri"
      ];

      # Toggle Night Mode
      "Mod+Shift+N".action.spawn = [
        "dms"
        "ipc"
        "call"
        "night-mode"
        "toggle"
      ];

      # ============================================
      # THEMING & CUSTOMIZATION
      # ============================================

      # Color Picker (DMS)
      "Mod+C".action.spawn = [
        "dms"
        "ipc"
        "call"
        "modal"
        "toggle"
        "color-picker"
      ];

      # DMS Wallpaper Selector (Media Hub/DankDash)
      "Mod+W".action.spawn = [
        "dms"
        "ipc"
        "call"
        "modal"
        "toggle"
        "dashboard"
      ];

      # ============================================
      # SCREENSHOTS - DMS CLI
      # ============================================

      # Region selection (default)
      "Print".action.spawn = [
        "dms"
        "screenshot"
      ];

      # Full screen of active display
      "Mod+Print".action.spawn = [
        "dms"
        "screenshot"
        "full"
      ];

      # All displays combined
      "Mod+Shift+Print".action.spawn = [
        "dms"
        "screenshot"
        "all"
      ];

      # Clipboard only (no file)
      "Ctrl+Print".action.spawn = [
        "dms"
        "screenshot"
        "--no-file"
      ];

      # ============================================
      # FOCUS CONTROL
      # ============================================

      # Alt+Tab window switching with DMS
      "Alt+Tab".action.spawn = [
        "quickshell"
        "-m"
        "dms.alttab"
      ];

      # # Arrow Keys - Focus Movement
      # "Mod+Left".action.focus-column-left = { };
      # "Mod+Right".action.focus-column-right = { };
      # "Mod+Up".action.focus-window-up = { };
      # "Mod+Down".action.focus-window-down = { };

      # # Vim Keys - Focus Movement
      # "Mod+H".action.focus-column-left = { };
      # "Mod+L".action.focus-column-right = { };
      # "Mod+K".action.focus-window-up = { };
      # "Mod+J".action.focus-window-down = { };

      # # ============================================
      # # MOVE WINDOW
      # # ============================================

      # # Arrow Keys
      # "Mod+Shift+Left".action.move-column-left = { };
      # "Mod+Shift+Right".action.move-column-right = { };
      # "Mod+Shift+Up".action.move-window-up = { };
      # "Mod+Shift+Down".action.move-window-down = { };

      # # Vim Keys
      # "Mod+Shift+H".action.move-column-left = { };
      # "Mod+Shift+L".action.move-column-right = { };
      # "Mod+Shift+K".action.move-window-up = { };
      # "Mod+Shift+J".action.move-window-down = { };

      # # Move to different outputs/monitors
      # "Mod+Ctrl+Shift+Left".action.move-column-to-output-left = { };
      # "Mod+Ctrl+Shift+Right".action.move-column-to-output-right = { };
      # "Mod+Ctrl+Shift+Up".action.move-column-to-output-up = { };
      # "Mod+Ctrl+Shift+Down".action.move-column-to-output-down = { };

      # # Vim Keys for output movement
      # "Mod+Ctrl+Shift+H".action.move-column-to-output-left = { };
      # "Mod+Ctrl+Shift+L".action.move-column-to-output-right = { };
      # "Mod+Ctrl+Shift+K".action.move-column-to-output-up = { };
      # "Mod+Ctrl+Shift+J".action.move-column-to-output-down = { };

      # ============================================
      # RESIZE WINDOW
      # ============================================

      # Arrow Keys
      # "Mod+Ctrl+Left".action.resize-column-left = 80;
      # "Mod+Ctrl+Right".action.resize-column-right = 80;
      # "Mod+Ctrl+Up".action.resize-window-up = 80;
      # "Mod+Ctrl+Down".action.resize-window-down = 80;

      # # Vim Keys
      # "Mod+Ctrl+H".action.resize-column-left = 80;
      # "Mod+Ctrl+L".action.resize-column-right = 80;
      # "Mod+Ctrl+K".action.resize-window-up = 80;
      # "Mod+Ctrl+J".action.resize-window-down = 80;

      # ============================================
      # MEDIA CONTROLS - DMS IPC
      # ============================================

      # Media playback
      "XF86AudioPlay".action.spawn = [
        "dms"
        "ipc"
        "call"
        "media"
        "play-pause"
      ];
      "XF86AudioNext".action.spawn = [
        "dms"
        "ipc"
        "call"
        "media"
        "next"
      ];
      "XF86AudioPrev".action.spawn = [
        "dms"
        "ipc"
        "call"
        "media"
        "previous"
      ];
      "XF86AudioStop".action.spawn = [
        "dms"
        "ipc"
        "call"
        "media"
        "stop"
      ];

      # Volume controls
      "XF86AudioRaiseVolume".action.spawn = [
        "dms"
        "ipc"
        "call"
        "audio"
        "volume-increment"
        "5"
      ];
      "XF86AudioLowerVolume".action.spawn = [
        "dms"
        "ipc"
        "call"
        "audio"
        "volume-decrement"
        "5"
      ];
      "XF86AudioMute".action.spawn = [
        "dms"
        "ipc"
        "call"
        "audio"
        "volume-toggle-mute"
      ];

      # Brightness controls (with OSD)
      "XF86MonBrightnessUp".action.spawn = [
        "dms"
        "ipc"
        "call"
        "brightness"
        "increment"
        "5"
      ];
      "XF86MonBrightnessDown".action.spawn = [
        "dms"
        "ipc"
        "call"
        "brightness"
        "decrement"
        "5"
      ];

      # ============================================
      # CLIPBOARD - DMS Integration
      # ============================================

      # DMS Clipboard history
      "Mod+V".action.spawn = [
        "dms"
        "ipc"
        "call"
        "modal"
        "toggle"
        "clipboard"
      ];
    };
  };
}
