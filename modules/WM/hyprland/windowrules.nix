_: {
  wayland.windowManager.hyprland.settings.windowrule = [
    # ============================================
    # DIALOG WINDOWS
    # ============================================
    "float, title:^(Open File|Save File|File Upload|Confirm to replace files|File Operation Progress)$"

    # ============================================
    # GNOME UTILITIES
    # ============================================
    "float, class:^(org\\.gnome\\.Calculator|org\\.gnome\\.FileRoller)$"

    # ============================================
    # SYSTEM UTILITIES
    # ============================================
    "float, class:^(org\\.pulseaudio\\.pavucontrol|zenity)$"

    # ============================================
    # IMAGE VIEWERS
    # ============================================
    "float, class:^(Viewnior|loupe|org\\.gnome\\.Loupe)$"
    "opacity 1.0 1.0, class:^(Viewnior|loupe|org\\.gnome\\.Loupe)$"

    # ============================================
    # MEDIA - Full Opacity
    # ============================================
    "float, class:^(mpv)$"
    "opacity 1.0 1.0, class:^(mpv)$"

    "float, title:^(Picture-in-Picture)$"
    "opacity 1.0 1.0, title:^(Picture-in-Picture)$"

    "opacity 1.0 1.0, class:^(jellyfin-desktop|com\\.github\\.iwalton3\\.jellyfin-media-player|google-chrome|zen|evince|org\\.gnome\\.Evince)$"

    # ============================================
    # GAMING
    # ============================================
    "float, class:^(\\.sameboy-wrapped)$"

    # ============================================
    # LAUNCHERS
    # ============================================
    "float, class:^(walker)$"

    # ============================================
    # VOLUME CONTROL
    # ============================================
    "float, title:^(Volume Control)$"

    # ============================================
    # TRANSMISSION
    # ============================================
    "float, title:^(Transmission)$"
  ];
}
