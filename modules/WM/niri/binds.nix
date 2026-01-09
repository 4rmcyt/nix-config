_: {
  programs.niri.settings = {
    binds = {
      # ============================================
      # APPLICATIONS
      # ============================================

      # Terminal
      "Super+Return".action.spawn = ["wezterm" "start" "--cwd" "."];
      "Alt+Return".action.spawn = ["wezterm" "start" "--cwd" "."];
      "Super+Shift+Return".action.spawn = ["wezterm" "start" "--cwd" "."];

      # Browser
      "Super+B".action.spawn = "chromium";

      # DMS Application Launcher (Primary)
      "Super+Space".action.spawn = ["quickshell" "-m" "dms.overview"];
      "Super+D".action.spawn = ["quickshell" "-m" "dms.overview"];

      # System Monitor (Use DMS Task Manager instead)
      "Ctrl+Shift+Escape".action.spawn = ["quickshell" "-m" "dms.taskmgr"];

      # DMS Task Manager
      "Super+M".action.spawn = ["quickshell" "-m" "dms.taskmgr"];

      # DMS Settings
      "Super+Comma".action.spawn = ["quickshell" "-m" "dms.settings"];

      # Communication
      "Super+Shift+D".action.spawn = ["discord" "--enable-features=UseOzonePlatform" "--ozone-platform=wayland"];

      # ============================================
      # WINDOW MANAGEMENT
      # ============================================

      # Close
      "Super+Q".action.close-window = {};

      # Fullscreen
      "Super+F".action.fullscreen-window = {};

      # Floating (moved from Super+Space to avoid conflict with DMS launcher)
      "Super+Shift+Space".action.toggle-floating = {};

      # ============================================
      # SYSTEM CONTROLS
      # ============================================

      # Power Menu (DMS)
      "Super+Shift+Escape".action.spawn = ["dms" "ipc" "call" "modal" "toggle" "power-menu"];

      # Notifications (DMS)
      "Super+N".action.spawn = ["dms" "ipc" "call" "modal" "toggle" "notifications"];

      # Keybinds Cheatsheet
      "Super+Slash".action.spawn = ["dms" "ipc" "call" "keybinds" "toggle" "niri"];

      # Toggle Theme (Light/Dark)
      "Super+T".action.spawn = ["dms" "ipc" "call" "appearance" "toggle-theme"];

      # Toggle Night Mode
      "Super+Shift+N".action.spawn = ["dms" "ipc" "call" "night-mode" "toggle"];

      # ============================================
      # THEMING & CUSTOMIZATION
      # ============================================

      # Color Picker (DMS)
      "Super+C".action.spawn = ["dms" "ipc" "call" "modal" "toggle" "color-picker"];

      # DMS Wallpaper Selector (Media Hub/DankDash)
      "Super+W".action.spawn = ["dms" "ipc" "call" "modal" "toggle" "dashboard"];

      # ============================================
      # SCREENSHOTS - DMS CLI
      # ============================================

      # Region selection (default)
      "Print".action.spawn = ["dms" "screenshot"];

      # Full screen of active display
      "Super+Print".action.spawn = ["dms" "screenshot" "full"];

      # All displays combined
      "Super+Shift+Print".action.spawn = ["dms" "screenshot" "all"];

      # Clipboard only (no file)
      "Ctrl+Print".action.spawn = ["dms" "screenshot" "--no-file"];

      # ============================================
      # FOCUS CONTROL
      # ============================================

      # Alt+Tab window switching with DMS
      "Alt+Tab".action.spawn = ["quickshell" "-m" "dms.alttab"];

      # Arrow Keys - Focus Movement
      "Super+Left".action.focus-column-left = {};
      "Super+Right".action.focus-column-right = {};
      "Super+Up".action.focus-window-up = {};
      "Super+Down".action.focus-window-down = {};

      # Vim Keys - Focus Movement
      "Super+H".action.focus-column-left = {};
      "Super+L".action.focus-column-right = {};
      "Super+K".action.focus-window-up = {};
      "Super+J".action.focus-window-down = {};

      # ============================================
      # MOVE WINDOW
      # ============================================

      # Arrow Keys
      "Super+Shift+Left".action.move-column-left = {};
      "Super+Shift+Right".action.move-column-right = {};
      "Super+Shift+Up".action.move-window-up = {};
      "Super+Shift+Down".action.move-window-down = {};

      # Vim Keys
      "Super+Shift+H".action.move-column-left = {};
      "Super+Shift+L".action.move-column-right = {};
      "Super+Shift+K".action.move-window-up = {};
      "Super+Shift+J".action.move-window-down = {};

      # Move to different outputs/monitors
      "Super+Ctrl+Shift+Left".action.move-column-to-output-left = {};
      "Super+Ctrl+Shift+Right".action.move-column-to-output-right = {};
      "Super+Ctrl+Shift+Up".action.move-column-to-output-up = {};
      "Super+Ctrl+Shift+Down".action.move-column-to-output-down = {};

      # Vim Keys for output movement
      "Super+Ctrl+Shift+H".action.move-column-to-output-left = {};
      "Super+Ctrl+Shift+L".action.move-column-to-output-right = {};
      "Super+Ctrl+Shift+K".action.move-column-to-output-up = {};
      "Super+Ctrl+Shift+J".action.move-column-to-output-down = {};

      # ============================================
      # RESIZE WINDOW
      # ============================================

      # Arrow Keys
      "Super+Ctrl+Left".action.resize-column-left = 80;
      "Super+Ctrl+Right".action.resize-column-right = 80;
      "Super+Ctrl+Up".action.resize-window-up = 80;
      "Super+Ctrl+Down".action.resize-window-down = 80;

      # Vim Keys
      "Super+Ctrl+H".action.resize-column-left = 80;
      "Super+Ctrl+L".action.resize-column-right = 80;
      "Super+Ctrl+K".action.resize-window-up = 80;
      "Super+Ctrl+J".action.resize-window-down = 80;

      # ============================================
      # MEDIA CONTROLS - DMS IPC
      # ============================================

      # Media playback
      "XF86AudioPlay".action.spawn = ["dms" "ipc" "call" "media" "play-pause"];
      "XF86AudioNext".action.spawn = ["dms" "ipc" "call" "media" "next"];
      "XF86AudioPrev".action.spawn = ["dms" "ipc" "call" "media" "previous"];
      "XF86AudioStop".action.spawn = ["dms" "ipc" "call" "media" "stop"];

      # Volume controls
      "XF86AudioRaiseVolume".action.spawn = ["dms" "ipc" "call" "audio" "volume-increment" "5"];
      "XF86AudioLowerVolume".action.spawn = ["dms" "ipc" "call" "audio" "volume-decrement" "5"];
      "XF86AudioMute".action.spawn = ["dms" "ipc" "call" "audio" "volume-toggle-mute"];

      # Brightness controls (with OSD)
      "XF86MonBrightnessUp".action.spawn = ["dms" "ipc" "call" "brightness" "increment" "5"];
      "XF86MonBrightnessDown".action.spawn = ["dms" "ipc" "call" "brightness" "decrement" "5"];

      # ============================================
      # CLIPBOARD - DMS Integration
      # ============================================

      # DMS Clipboard history
      "Super+V".action.spawn = ["dms" "ipc" "call" "modal" "toggle" "clipboard"];
    };
  };
}
