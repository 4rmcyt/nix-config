{config, ...}: let
  a = config.lib.niri.actions;
  qs = target: act: {
    action = a.spawn "qs" "-c" "noctalia-shell" "ipc" "call" target act;
  };
in {
  programs.niri.settings.binds = {
    # ============================================
    # APPLICATIONS
    # ============================================

    "Mod+Return".action = a.spawn "kitty";
    "Mod+B".action = a.spawn "chromium";
    "Mod+E".action = a.spawn "nautilus";
    "Mod+Space" = qs "launcher" "toggle";
    "Mod+D" = qs "launcher" "toggle";
    "Mod+M".action = a.spawn "kitty" "-e" "btop";
    "Ctrl+Shift+Escape".action = a.spawn "kitty" "-e" "btop";
    "Mod+Comma" = qs "settings" "toggle";
    "Mod+Shift+D".action = a.spawn "discord" "--enable-features=UseOzonePlatform" "--ozone-platform=wayland";

    # ============================================
    # WINDOW MANAGEMENT
    # ============================================

    "Mod+Q".action = a.close-window;
    "Mod+F".action = a.maximize-column;
    "Mod+Shift+F".action = a.fullscreen-window;
    "Mod+Shift+Space".action = a.toggle-window-floating;

    # ============================================
    # SYSTEM CONTROLS
    # ============================================

    "Mod+Escape" = qs "lockScreen" "lock";
    "Mod+Shift+Escape" = qs "sessionMenu" "toggle";
    "Mod+N" = qs "notifications" "toggleHistory";
    "Mod+T" = qs "darkMode" "toggle";
    "Mod+Shift+N" = qs "nightLight" "toggle";

    # ============================================
    # THEMING & CUSTOMIZATION
    # ============================================

    "Mod+C" = qs "colorPicker" "toggle";
    "Mod+W" = qs "desktopWidgets" "toggle";

    # ============================================
    # SCREENSHOTS - niri native
    # ============================================

    "Print".action.screenshot = {};
    "Mod+Print".action.screenshot-screen = {};
    "Mod+Shift+Print".action.screenshot-screen = {};
    "Ctrl+Print".action.screenshot = {};

    # ============================================
    # FOCUS CONTROL
    # ============================================

    "Alt+Tab".action = a.focus-window-previous;

    # Arrow Keys
    "Mod+Left".action = a.focus-column-left;
    "Mod+Right".action = a.focus-column-right;
    "Mod+Up".action = a.focus-window-up;
    "Mod+Down".action = a.focus-window-down;

    # Vim Keys
    "Mod+H".action = a.focus-column-left;
    "Mod+L".action = a.focus-column-right;
    "Mod+K".action = a.focus-window-up;
    "Mod+J".action = a.focus-window-down;

    # ============================================
    # MOVE WINDOW
    # ============================================

    "Mod+Ctrl+Left".action = a.move-column-left;
    "Mod+Ctrl+Right".action = a.move-column-right;
    "Mod+Ctrl+Up".action = a.move-window-up;
    "Mod+Ctrl+Down".action = a.move-window-down;

    "Mod+Ctrl+H".action = a.move-column-left;
    "Mod+Ctrl+L".action = a.move-column-right;
    "Mod+Ctrl+K".action = a.move-window-up;
    "Mod+Ctrl+J".action = a.move-window-down;

    # ============================================
    # MONITOR FOCUS
    # ============================================

    "Mod+Shift+Left".action = a.focus-monitor-left;
    "Mod+Shift+Right".action = a.focus-monitor-right;
    "Mod+Shift+Up".action = a.focus-monitor-up;
    "Mod+Shift+Down".action = a.focus-monitor-down;

    "Mod+Shift+H".action = a.focus-monitor-left;
    "Mod+Shift+L".action = a.focus-monitor-right;
    "Mod+Shift+K".action = a.focus-monitor-up;
    "Mod+Shift+J".action = a.focus-monitor-down;

    # ============================================
    # MOVE TO MONITOR
    # ============================================

    "Mod+Shift+Ctrl+Left".action = a.move-column-to-monitor-left;
    "Mod+Shift+Ctrl+Right".action = a.move-column-to-monitor-right;
    "Mod+Shift+Ctrl+Up".action = a.move-column-to-monitor-up;
    "Mod+Shift+Ctrl+Down".action = a.move-column-to-monitor-down;

    "Mod+Shift+Ctrl+H".action = a.move-column-to-monitor-left;
    "Mod+Shift+Ctrl+L".action = a.move-column-to-monitor-right;
    "Mod+Shift+Ctrl+K".action = a.move-column-to-monitor-up;
    "Mod+Shift+Ctrl+J".action = a.move-column-to-monitor-down;

    # ============================================
    # WORKSPACES
    # ============================================

    "Mod+1".action = a.focus-workspace 1;
    "Mod+2".action = a.focus-workspace 2;
    "Mod+3".action = a.focus-workspace 3;
    "Mod+4".action = a.focus-workspace 4;
    "Mod+5".action = a.focus-workspace 5;
    "Mod+6".action = a.focus-workspace 6;
    "Mod+7".action = a.focus-workspace 7;
    "Mod+8".action = a.focus-workspace 8;
    "Mod+9".action = a.focus-workspace 9;

    "Mod+Ctrl+Page_Down".action = a.move-column-to-workspace-down;
    "Mod+Ctrl+Page_Up".action = a.move-column-to-workspace-up;

    "Mod+Page_Down".action = a.focus-workspace-down;
    "Mod+Page_Up".action = a.focus-workspace-up;

    "Mod+Shift+Page_Down".action = a.move-workspace-down;
    "Mod+Shift+Page_Up".action = a.move-workspace-up;

    # ============================================
    # COLUMN OPERATIONS
    # ============================================

    "Mod+BracketLeft".action = a.consume-or-expel-window-left;
    "Mod+BracketRight".action = a.consume-or-expel-window-right;
    "Mod+R".action = a.switch-preset-column-width;
    "Mod+Shift+C".action = a.center-column;

    # ============================================
    # RESIZE
    # ============================================

    "Mod+Minus".action = a.set-column-width "-10%";
    "Mod+Equal".action = a.set-column-width "+10%";
    "Mod+Shift+Minus".action = a.set-window-height "-10%";
    "Mod+Shift+Equal".action = a.set-window-height "+10%";

    # ============================================
    # MEDIA CONTROLS
    # ============================================

    "XF86AudioPlay".action = a.spawn "playerctl" "play-pause";
    "XF86AudioNext".action = a.spawn "playerctl" "next";
    "XF86AudioPrev".action = a.spawn "playerctl" "previous";
    "XF86AudioStop".action = a.spawn "playerctl" "stop";
    "XF86AudioRaiseVolume".action = a.spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+";
    "XF86AudioLowerVolume".action = a.spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";
    "XF86AudioMute".action = a.spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
    "XF86MonBrightnessUp".action = a.spawn "brightnessctl" "set" "5%+";
    "XF86MonBrightnessDown".action = a.spawn "brightnessctl" "set" "5%-";

    # ============================================
    # CLIPBOARD
    # ============================================

    "Mod+V" = qs "launcher" "clipboard";

    # ============================================
    # SYSTEM
    # ============================================

    "Mod+Shift+E".action = a.quit;
    "Mod+Shift+P".action = a.power-off-monitors;
    "Mod+Shift+Slash".action = a.show-hotkey-overlay;
  };
}
