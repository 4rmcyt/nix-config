_: {
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # DMS Modals
      "float on, match:class ^(dms:settings)$"
      "float on, match:class ^(dms:power-menu)$"
      "float on, match:class ^(dms:clipboard)$"
      "float on, match:class ^(dms:spotlight)$"
      "float on, match:class ^(dms:polkit)$"
      "float on, match:class ^(dms:modal)$"

      # DMS Popouts
      "float on, match:class ^(dms:app-launcher)$"
      "float on, match:class ^(dms:control-center)$"
      "float on, match:class ^(dms:notification-center-popout)$"
      "float on, match:class ^(dms:popout)$"

      # DMS Bar and Misc
      "float on, match:class ^(dms:bar)$"
      "float on, match:class ^(dms:dock)$"
      "float on, match:class ^(dms:osd)$"
      "float on, match:class ^(dms:notification)$"
      "float on, match:class ^(dms:tooltip)$"

      # QuickShell
      "float on, match:class ^(quickshell)$"

      # GNOME
      "decorate off, match:class ^(org\\.gnome\\..*)$"
      "float on, match:class ^(org.gnome.Calculator)$"
      "float on, match:class ^(org.gnome.FileRoller)$"

      # Image Viewers
      "float on, match:class ^(Viewnior)$"
      "float on, match:class ^(loupe)$"
      "float on, match:class ^(org.gnome.Loupe)$"

      # Media Players
      "float on, match:class ^(mpv)$"
      "float on, match:title ^(Picture-in-Picture)$"
      "pin on, match:title ^(Picture-in-Picture)$"

      # File Management
      "float on, match:title ^(Open File)$"
      "float on, match:title ^(Save File)$"

      # System Utilities
      "float on, match:class ^(org.pulseaudio.pavucontrol)$"

      # Launchers & Menus
      "pin on, match:class ^(walker)$"
      "float on, match:class ^(zenity)$"
      "size 850 500, match:class ^(zenity)$"

      # Gaming
      "float on, match:class ^(.sameboy-wrapped)$"

      # Dialog Windows
      "float on, match:class ^(file_progress)$"
      "float on, match:class ^(confirm)$"
      "float on, match:class ^(dialog)$"
      "float on, match:class ^(download)$"
      "float on, match:class ^(notification)$"
      "float on, match:class ^(error)$"
      "float on, match:class ^(confirmreset)$"
      "float on, match:title ^(File Upload)$"
      "float on, match:title ^(branchdialog)$"
      "float on, match:title ^(Confirm to replace files)$"
      "float on, match:title ^(File Operation Progress)$"

      # Transmission
      "float on, match:title ^(Transmission)$"

      # Volume Control
      "float on, match:title ^(Volume Control)$"
      "size 700 450, match:title ^(Volume Control)$"
      "move 40 55%, match:title ^(Volume Control)$"

      # Firefox
      "float on, match:title ^(Firefox — Sharing Indicator)$"
      "move 0 0, match:title ^(Firefox — Sharing Indicator)$"

      # Tiling Overrides
      "tile on, match:class ^(Aseprite)$"

      # Opacity Overrides
      "opacity 1.0 override 1.0 override, match:title ^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, match:class (loupe)"
      "opacity 1.0 override 1.0 override, match:class (org.gnome.Loupe)"
      "opacity 1.0 override 1.0 override, match:title ^(.*mpv.*)$"
      "opacity 1.0 override 1.0 override, match:class (Aseprite)"
      "opacity 1.0 override 1.0 override, match:class (Unity)"
      "opacity 1.0 override 1.0 override, match:class (zen)"
      "opacity 1.0 override 1.0 override, match:class (evince)"
      "opacity 1.0 override 1.0 override, match:class (org.gnome.Evince)"
      "opacity 1.0 override 1.0 override, match:class (jellyfin-desktop)"
      "opacity 1.0 override 1.0 override, match:class (com.github.iwalton3.jellyfin-media-player)"
      "opacity 1.0 override 1.0 override, match:class (chromium-browser)"

      # Idle Inhibit
      "idle_inhibit focus, match:class ^(mpv)$"
      "idle_inhibit fullscreen, match:class ^(firefox)$"
      "idle_inhibit fullscreen, match:class ^(jellyfin-desktop)$"
      "idle_inhibit fullscreen, match:class ^(chromium-browser)$"

      # Xwayland Video Bridge
      "opacity 0.0 override, match:class ^(xwaylandvideobridge)$"
      "no_anim on, match:class ^(xwaylandvideobridge)$"
      "no_initial_focus on, match:class ^(xwaylandvideobridge)$"
      "max_size 1 1, match:class ^(xwaylandvideobridge)$"
      "no_blur on, match:class ^(xwaylandvideobridge)$"

      # No Gaps/Borders for Fullscreen Workspaces
      "border_size 0, match:class .*, match:workspace w[t1]"
      "rounding 0, match:class .*, match:workspace w[t1]"
      "border_size 0, match:class .*, match:workspace w[tg1]"
      "rounding 0, match:class .*, match:workspace w[tg1]"
      "border_size 0, match:class .*, match:workspace f[1]"
      "rounding 0, match:class .*, match:workspace f[1]"

      # Chromium Context Menu Fix
      "opaque on, match:class ^()$, match:title ^()$"
      "no_shadow on, match:class ^()$, match:title ^()$"
      "no_blur on, match:class ^()$, match:title ^()$"
    ];

    workspace = [
      "w[t1],gapsout:0,gapsin:0"
      "w[tg1],gapsout:0,gapsin:0"
      "f[1],gapsout:0,gapsin:0"
    ];
  };
}
