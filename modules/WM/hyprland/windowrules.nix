_: let
  rule = name: match: effects: {_args = [({inherit name match;} // effects)];};
in {
  wayland.windowManager.hyprland.settings.window_rule = [
    # ============================================
    # DIALOG WINDOWS
    # ============================================
    (rule "dialog-windows" {
      title = "^(Open File|Save File|File Upload|Confirm to replace files|File Operation Progress)$";
    } {float = true;})

    # ============================================
    # GNOME UTILITIES
    # ============================================
    (rule "gnome-utilities" {
      class = "^(org\\.gnome\\.Calculator|org\\.gnome\\.FileRoller)$";
    } {float = true;})

    # ============================================
    # SYSTEM UTILITIES
    # ============================================
    (rule "system-utilities" {
      class = "^(org\\.pulseaudio\\.pavucontrol|zenity)$";
    } {float = true;})

    # ============================================
    # IMAGE VIEWERS
    # ============================================
    (rule "image-viewers" {
        class = "^(Viewnior|loupe|org\\.gnome\\.Loupe)$";
      } {
        float = true;
        opacity = "1.0 1.0";
      })

    # ============================================
    # MEDIA - Full Opacity
    # ============================================
    (rule "mpv" {class = "^(mpv)$";} {
      float = true;
      opacity = "1.0 1.0";
    })

    (rule "picture-in-picture" {
        title = "^(Picture-in-Picture)$";
      } {
        float = true;
        opacity = "1.0 1.0";
      })

    (rule "full-opacity-apps" {
      class = "^(jellyfin-desktop|com\\.github\\.iwalton3\\.jellyfin-media-player|google-chrome|zen|evince|org\\.gnome\\.Evince)$";
    } {opacity = "1.0 1.0";})

    # ============================================
    # GAMING
    # ============================================
    (rule "gaming-sameboy" {
      class = "^(\\.sameboy-wrapped)$";
    } {float = true;})

    # ============================================
    # LAUNCHERS
    # ============================================
    (rule "launcher-walker" {class = "^(walker)$";} {float = true;})

    # ============================================
    # VOLUME CONTROL
    # ============================================
    (rule "volume-control" {
      title = "^(Volume Control)$";
    } {float = true;})

    # ============================================
    # TRANSMISSION
    # ============================================
    (rule "transmission" {
      title = "^(Transmission)$";
    } {float = true;})
  ];
}
