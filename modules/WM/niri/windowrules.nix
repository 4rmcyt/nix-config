_: {
  programs.niri.settings = {
    window-rules = [
      # ============================================
      # DIALOG WINDOWS
      # ============================================
      {
        matches = [
          {title = "^Open File$";}
          {title = "^Save File$";}
          {title = "^File Upload$";}
          {title = "^Confirm to replace files$";}
          {title = "^File Operation Progress$";}
        ];
        open-floating = true;
      }

      # ============================================
      # GNOME UTILITIES
      # ============================================
      {
        matches = [
          {app-id = "^org\\.gnome\\.Calculator$";}
          {app-id = "^org\\.gnome\\.FileRoller$";}
        ];
        open-floating = true;
      }

      # ============================================
      # SYSTEM UTILITIES
      # ============================================
      {
        matches = [
          {app-id = "^org\\.pulseaudio\\.pavucontrol$";}
          {app-id = "^zenity$";}
        ];
        open-floating = true;
      }

      # ============================================
      # IMAGE VIEWERS
      # ============================================
      {
        matches = [
          {app-id = "^Viewnior$";}
          {app-id = "^loupe$";}
          {app-id = "^org\\.gnome\\.Loupe$";}
        ];
        open-floating = true;
        opacity = 1.0;
      }

      # ============================================
      # MEDIA - Full Opacity
      # ============================================
      {
        matches = [
          {app-id = "^mpv$";}
        ];
        open-floating = true;
        opacity = 1.0;
      }

      {
        matches = [
          {title = "^Picture-in-Picture$";}
        ];
        open-floating = true;
        opacity = 1.0;
      }

      {
        matches = [
          {app-id = "^jellyfin-desktop$";}
          {app-id = "^com\\.github\\.iwalton3\\.jellyfin-media-player$";}
          {app-id = "^google-chrome$";}
          {app-id = "^zen$";}
          {app-id = "^evince$";}
          {app-id = "^org\\.gnome\\.Evince$";}
        ];
        opacity = 1.0;
      }

      # ============================================
      # GAMING
      # ============================================
      {
        matches = [
          {app-id = "^\\.sameboy-wrapped$";}
        ];
        open-floating = true;
      }

      # ============================================
      # LAUNCHERS
      # ============================================
      {
        matches = [
          {app-id = "^walker$";}
        ];
        open-floating = true;
      }

      # ============================================
      # VOLUME CONTROL
      # ============================================
      {
        matches = [
          {title = "^Volume Control$";}
        ];
        open-floating = true;
      }

      # ============================================
      # TRANSMISSION
      # ============================================
      {
        matches = [
          {title = "^Transmission$";}
        ];
        open-floating = true;
      }
    ];
  };
}
