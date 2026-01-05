_: {
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      # ============================================
      # FLOATING WINDOWS
      # ============================================

      # Image Viewers
      "float,  class:^(Viewnior)$"
      "float,  class:^(org.kde.gwenview)$"

      # Media Players
      "float,  class:^(mpv)$"
      "float,  title:^(Picture-in-Picture)$"
      "pin,  title:^(Picture-in-Picture)$"

      # File Management
      "float,  class:^(waypaper)$"
      "pin,  class:^(waypaper)$"
      "float,  class:^(org.gnome.FileRoller)$"

      # System Utilities
      "float,  class:^(org.gnome.Calculator)$"
      "float,  class:^(org.pulseaudio.pavucontrol)$"
      "float,  class:^(SoundWireServer)$"
      "size 725 330,  class:^(SoundWireServer)$"

      # Launchers & Menus
      "pin,  class:^(walker)$"
      "float,  class:^(zenity)$"
      "size 850 500,  class:^(zenity)$"

      # Gaming
      "float,  class:^(.sameboy-wrapped)$"

      # ============================================
      # DIALOG WINDOWS
      # ============================================
      "float, class:^(file_progress)$"
      "float, class:^(confirm)$"
      "float, class:^(dialog)$"
      "float, class:^(download)$"
      "float, class:^(notification)$"
      "float, class:^(error)$"
      "float, class:^(confirmreset)$"
      "float, title:^(Open File)$"
      "float, title:^(File Upload)$"
      "float, title:^(branchdialog)$"
      "float, title:^(Confirm to replace files)$"
      "float, title:^(File Operation Progress)$"

      # ============================================
      # APPLICATION-SPECIFIC
      # ============================================

      # Transmission
      "float, title:^(Transmission)$"

      # Volume Control
      "float, title:^(Volume Control)$"
      "size 700 450, title:^(Volume Control)$"
      "move 40 55%, title:^(Volume Control)$"

      # Firefox
      "float, title:^(Firefox — Sharing Indicator)$"
      "move 0 0, title:^(Firefox — Sharing Indicator)$"

      # ============================================
      # TILING OVERRIDES
      # ============================================
      "tile, class:^(Aseprite)$"

      # ============================================
      # OPACITY OVERRIDES
      # ============================================
      "opacity 1.0 override 1.0 override, title:^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, class:(org.kde.gwenview)"
      "opacity 1.0 override 1.0 override, title:^(.*mpv.*)$"
      "opacity 1.0 override 1.0 override, class:(Aseprite)"
      "opacity 1.0 override 1.0 override, class:(Unity)"
      "opacity 1.0 override 1.0 override, class:(zen)"
      "opacity 1.0 override 1.0 override, class:(org.kde.okular)"

      # ============================================
      # WORKSPACE ASSIGNMENTS - Disabled (single workspace)
      # ============================================
      # All windows stay on workspace 1

      # ============================================
      # IDLE INHIBIT
      # ============================================
      "idleinhibit focus, class:^(mpv)$"
      "idleinhibit fullscreen, class:^(firefox)$"

      # ============================================
      # XWAYLAND VIDEO BRIDGE
      # ============================================
      "opacity 0.0 override, class:^(xwaylandvideobridge)$"
      "noanim, class:^(xwaylandvideobridge)$"
      "noinitialfocus, class:^(xwaylandvideobridge)$"
      "maxsize 1 1, class:^(xwaylandvideobridge)$"
      "noblur, class:^(xwaylandvideobridge)$"

      # ============================================
      # NO GAPS/BORDERS FOR FULLSCREEN WORKSPACES
      # ============================================
      "bordersize 0, floating:0,onworkspace:w[t1]"
      "rounding 0, floating:0,onworkspace:w[t1]"
      "bordersize 0, floating:0,onworkspace:w[tg1]"
      "rounding 0, floating:0,onworkspace:w[tg1]"
      "bordersize 0, floating:0,onworkspace:f[1]"
      "rounding 0, floating:0,onworkspace:f[1]"

      # ============================================
      # CHROMIUM CONTEXT MENU FIX
      # ============================================
      "opaque, class:^()$,title:^()$"
      "noshadow, class:^()$,title:^()$"
      "noblur, class:^()$,title:^()$"
    ];

    # ============================================
    # WORKSPACE RULES
    # ============================================
    workspace = [
      "w[t1],gapsout:0,gapsin:0"
      "w[tg1],gapsout:0,gapsin:0"
      "f[1],gapsout:0,gapsin:0"
    ];
  };
}
