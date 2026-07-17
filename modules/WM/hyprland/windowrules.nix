_: {
  # Non-deprecated windowrule syntax for Hyprland 0.55+ hyprlang (classic
  # windowrule/windowrulev2 comma-list form errors with "missing a value" on
  # this version). Confirmed working live via `hyprctl keyword windowrule`:
  # "match:<field> <regex>, <effect> <value>" — space after match:field, not
  # a colon.
  wayland.windowManager.hyprland.settings.windowrule = [
    # ============================================
    # DIALOG WINDOWS
    # ============================================
    "match:title ^(Open File|Save File|File Upload|Confirm to replace files|File Operation Progress)$, float on"

    # ============================================
    # GNOME UTILITIES
    # ============================================
    "match:class ^(org\\.gnome\\.Calculator|org\\.gnome\\.FileRoller)$, float on"

    # ============================================
    # SYSTEM UTILITIES
    # ============================================
    "match:class ^(org\\.pulseaudio\\.pavucontrol|zenity)$, float on"

    # ============================================
    # IMAGE VIEWERS
    # ============================================
    "match:class ^(Viewnior|loupe|org\\.gnome\\.Loupe)$, float on"
    "match:class ^(Viewnior|loupe|org\\.gnome\\.Loupe)$, opacity 1.0 1.0"

    # ============================================
    # MEDIA - Full Opacity
    # ============================================
    "match:class ^(mpv)$, float on"
    "match:class ^(mpv)$, opacity 1.0 1.0"

    "match:title ^(Picture-in-Picture)$, float on"
    "match:title ^(Picture-in-Picture)$, opacity 1.0 1.0"

    "match:class ^(jellyfin-desktop|com\\.github\\.iwalton3\\.jellyfin-media-player|google-chrome|zen|evince|org\\.gnome\\.Evince)$, opacity 1.0 1.0"

    # ============================================
    # GAMING
    # ============================================
    "match:class ^(\\.sameboy-wrapped)$, float on"

    # ============================================
    # LAUNCHERS
    # ============================================
    "match:class ^(walker)$, float on"

    # ============================================
    # VOLUME CONTROL
    # ============================================
    "match:title ^(Volume Control)$, float on"

    # ============================================
    # TRANSMISSION
    # ============================================
    "match:title ^(Transmission)$, float on"
  ];
}
