_: {
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # ============================================
      # DMS COMPONENTS
      # ============================================

      # DMS Modals (full-screen overlays)
      "float, class:^(dms:settings)$"
      "float, class:^(dms:power-menu)$"
      "float, class:^(dms:clipboard)$"
      "float, class:^(dms:spotlight)$"
      "float, class:^(dms:polkit)$"
      "float, class:^(dms:modal)$"

      # DMS Popouts (bar-anchored panels)
      "float, class:^(dms:app-launcher)$"
      "float, class:^(dms:control-center)$"
      "float, class:^(dms:notification-center-popout)$"
      "float, class:^(dms:popout)$"

      # DMS Bar and Misc Components
      "float, class:^(dms:bar)$"
      "float, class:^(dms:dock)$"
      "float, class:^(dms:osd)$"
      "float, class:^(dms:notification)$"
      "float, class:^(dms:tooltip)$"

      # QuickShell (DMS runtime)
      "float, class:^(quickshell)$"

      # ============================================
      # GNOME APPLICATIONS
      # ============================================

      # GNOME apps get proper borders
      "noborder, class:^(org\\.gnome\\..*)$"

      # GNOME Calculator
      "float, class:^(org.gnome.Calculator)$"

      # GNOME File Roller
      "float, class:^(org.gnome.FileRoller)$"

      # ============================================
      # FLOATING WINDOWS
      # ============================================

      # Image Viewers
      "float, class:^(Viewnior)$"
      "float, class:^(loupe)$"
      "float, class:^(org.gnome.Loupe)$"

      # Media Players
      "float, class:^(mpv)$"
      "float, title:^(Picture-in-Picture)$"
      "pin, title:^(Picture-in-Picture)$"

      # File Management
      "float, title:^(Open File)$"
      "float, title:^(Save File)$"

      # System Utilities
      "float, class:^(org.pulseaudio.pavucontrol)$"

      # Launchers & Menus
      "pin, class:^(walker)$"
      "float, class:^(zenity)$"
      "size 850 500, class:^(zenity)$"

      # Gaming
      "float, class:^(.sameboy-wrapped)$"

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
      # OPACITY OVERRIDES (DMS recommended: 0.9 for inactive)
      # ============================================
      "opacity 1.0 override 1.0 override, title:^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, class:(loupe)"
      "opacity 1.0 override 1.0 override, class:(org.gnome.Loupe)"
      "opacity 1.0 override 1.0 override, title:^(.*mpv.*)$"
      "opacity 1.0 override 1.0 override, class:(Aseprite)"
      "opacity 1.0 override 1.0 override, class:(Unity)"
      "opacity 1.0 override 1.0 override, class:(zen)"
      "opacity 1.0 override 1.0 override, class:(evince)"
      "opacity 1.0 override 1.0 override, class:(org.gnome.Evince)"
      "opacity 1.0 override 1.0 override, class:(jellyfin-desktop)"
      "opacity 1.0 override 1.0 override, class:(com.github.iwalton3.jellyfin-media-player)"
      "opacity 1.0 override 1.0 override, class:(chromium-browser)"
      "opacity 0.9, tiled:1" # DMS recommended inactive opacity

      # ============================================
      # WORKSPACE ASSIGNMENTS - Disabled (single workspace)
      # ============================================
      # All windows stay on workspace 1

      # ============================================
      # IDLE INHIBIT
      # ============================================
      "idleinhibit focus, class:^(mpv)$"
      "idleinhibit fullscreen, class:^(firefox)$"
      "idleinhibit fullscreen, class:^(jellyfin-desktop)$"
      "idleinhibit fullscreen, class:^(chromium-browser)$"

      # ============================================
      # HDR SUPPORT
      # ============================================
      "hdr, class:^(jellyfin-desktop)$"
      "hdr, class:^(com.github.iwalton3.jellyfin-media-player)$"
      "hdr, class:^(chromium-browser)$"
      "hdr, class:^(chromium)$"

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
      "bordersize 0, tiled:1,onworkspace:w[t1]"
      "rounding 0, tiled:1,onworkspace:w[t1]"
      "bordersize 0, tiled:1,onworkspace:w[tg1]"
      "rounding 0, tiled:1,onworkspace:w[tg1]"
      "bordersize 0, tiled:1,onworkspace:f[1]"
      "rounding 0, tiled:1,onworkspace:f[1]"

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
