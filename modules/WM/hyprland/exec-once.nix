_: {
  wayland.windowManager.hyprland.settings.exec-once = [
    # ============================================
    # ENVIRONMENT SETUP
    # ============================================
    "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

    # ============================================
    # SECURITY
    # ============================================
    "hyprlock"

    # ============================================
    # SYSTEM TRAY & SERVICES
    # ============================================
    "nm-applet &"
    "poweralertd &"
    "udiskie --automount --notify --smart-tray &"

    # ============================================
    # CLIPBOARD
    # ============================================
    "wl-clip-persist --clipboard both &"
    "wl-paste --watch cliphist store &"

    # ============================================
    # UI COMPONENTS
    # ============================================
    "waybar &"
    "swaync &"
    "hyprctl setcursor Bibata-Modern-Ice 24 &"
    "init-wallpaper &"

    # ============================================
    # APPLICATIONS
    # ============================================
    "wezterm --config-file /home/zeev/.config/wezterm/wezterm.lua"
    "[workspace 1 silent] chromium"
  ];
}
