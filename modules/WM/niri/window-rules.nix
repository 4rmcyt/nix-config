_: {
  programs.niri.settings = {
    window-rules = [
      # ============================================
      # DMS COMPONENTS
      # ============================================

      # DMS Modals (full-screen overlays)
      {
        matches = [
          {app-id = "^dms:settings$";}
          {app-id = "^dms:power-menu$";}
          {app-id = "^dms:clipboard$";}
          {app-id = "^dms:spotlight$";}
          {app-id = "^dms:polkit$";}
          {app-id = "^dms:modal$";}
        ];
        open-floating = true;
        default-column-width = {};
      }

      # DMS Popouts (bar-anchored panels)
      {
        matches = [
          {app-id = "^dms:app-launcher$";}
          {app-id = "^dms:control-center$";}
          {app-id = "^dms:notification-center-popout$";}
          {app-id = "^dms:popout$";}
        ];
        open-floating = true;
        default-column-width = {};
      }

      # DMS Bar and Misc Components
      {
        matches = [
          {app-id = "^dms:bar$";}
          {app-id = "^dms:dock$";}
          {app-id = "^dms:osd$";}
          {app-id = "^dms:notification$";}
          {app-id = "^dms:tooltip$";}
        ];
        open-floating = true;
        default-column-width = {};
      }

      # QuickShell (DMS runtime)
      {
        matches = [{app-id = "^quickshell$";}];
        open-floating = true;
        default-column-width = {};
      }

      # ============================================
      # GNOME APPLICATIONS
      # ============================================

      # GNOME apps with transparent borders
      {
        matches = [
          {app-id = "^org\\.gnome\\..*$";}
        ];
        draw-border-with-background = false;
      }

      # ============================================
      # GENERAL WINDOW STYLING
      # ============================================

      # Corner radius for all windows (DMS recommended: 12px)
      {
        geometry-corner-radius = {
          bottom-left = 12.0;
          bottom-right = 12.0;
          top-left = 12.0;
          top-right = 12.0;
        };
        clip-to-geometry = true;
      }

      # Window opacity for all windows (DMS recommended: 0.9)
      # Applies to both active and inactive windows
      {
        opacity = 0.9;
      }

      # ============================================
      # FLOATING WINDOWS
      # ============================================

      # System dialogs and file pickers
      {
        matches = [
          {app-id = "^xdg-desktop-portal-.*$";}
          {title = "^Open.*$";}
          {title = "^Save.*$";}
        ];
        open-floating = true;
      }

      # ============================================
      # SPECIAL APPLICATIONS
      # ============================================

      # Picture-in-picture windows
      {
        matches = [
          {title = "^Picture-in-Picture$";}
          {title = "^Picture in picture$";}
        ];
        open-floating = true;
      }
    ];
  };
}
