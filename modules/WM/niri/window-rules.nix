_: {
  programs.niri.settings = {
    window-rules = [
      {
        default-column-width = {};
        matches = [
          {app-id = "^dms:clipboard$";}
          {app-id = "^dms:modal$";}
          {app-id = "^dms:polkit$";}
          {app-id = "^dms:power-menu$";}
          {app-id = "^dms:settings$";}
          {app-id = "^dms:spotlight$";}
        ];
        open-floating = true;
      }
      {
        default-column-width = {};
        matches = [
          {app-id = "^dms:app-launcher$";}
          {app-id = "^dms:control-center$";}
          {app-id = "^dms:notification-center-popout$";}
          {app-id = "^dms:popout$";}
        ];
        open-floating = true;
      }
      {
        default-column-width = {};
        matches = [
          {app-id = "^dms:bar$";}
          {app-id = "^dms:dock$";}
          {app-id = "^dms:notification$";}
          {app-id = "^dms:osd$";}
          {app-id = "^dms:tooltip$";}
        ];
        open-floating = true;
      }
      {
        default-column-width = {};
        matches = [{app-id = "^quickshell$";}];
        open-floating = true;
      }
      {
        draw-border-with-background = false;
        matches = [
          {app-id = "^org\\.gnome\\..*$";}
        ];
      }
      {
        clip-to-geometry = true;
        geometry-corner-radius = {
          bottom-left = 12.0;
          bottom-right = 12.0;
          top-left = 12.0;
          top-right = 12.0;
        };
        opacity = 0.9;
      }
      {
        matches = [
          {app-id = "^xdg-desktop-portal-.*$";}
          {title = "^Open.*$";}
          {title = "^Save.*$";}
        ];
        open-floating = true;
      }
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
