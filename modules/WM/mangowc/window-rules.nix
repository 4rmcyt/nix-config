_: {
  # ============================================
  # MANGOWC WINDOW RULES
  # ============================================
  # Note: MangoWC is based on dwl/wlroots and uses a config.h file for window rules.
  # This file documents the recommended window rules for DMS integration.

  # Documentation of recommended window rules for MangoWC + DMS
  home.file.".config/mangowc/window-rules.md".text = ''
    # MangoWC + DMS Window Rules

    Configure these in your MangoWC config.h or rules configuration.

    ## DMS COMPONENTS - Float by default

    ### DMS Modals (full-screen overlays)
    - `dms:settings` - DMS Settings modal
    - `dms:power-menu` - Power menu modal
    - `dms:clipboard` - Clipboard history modal
    - `dms:spotlight` - Spotlight search modal
    - `dms:polkit` - Polkit authentication modal
    - `dms:modal` - Generic DMS modals

    ### DMS Popouts (bar-anchored panels)
    - `dms:app-launcher` - Application launcher popout
    - `dms:control-center` - Control center popout
    - `dms:notification-center-popout` - Notification center popout
    - `dms:popout` - Generic DMS popouts

    ### DMS Bar and Misc Components
    - `dms:bar` - DMS status bar
    - `dms:dock` - DMS dock
    - `dms:osd` - On-screen display (volume/brightness)
    - `dms:notification` - Notification popups
    - `dms:tooltip` - Tooltips

    ### QuickShell (DMS runtime)
    - `quickshell` - QuickShell windows (float by default)

    ## GNOME APPLICATIONS
    - Match: `org.gnome.*`
    - No borders/decorations (client-side decorations)

    ## FLOATING WINDOWS
    - XDG desktop portals (file pickers, etc.)
    - Titles matching: "^Open.*$", "^Save.*$"
    - Picture-in-Picture windows

    ## OPACITY
    - Default opacity: 0.9 for inactive windows
    - Full opacity (1.0) for:
      - Media players (mpv, jellyfin-desktop)
      - Image viewers (loupe, evince)
      - Games (Unity, Aseprite)
      - Browsers (chromium, zen)

    ## ROUNDED CORNERS
    - Corner radius: 12px for all windows
  '';

  # Example config.h snippet for window rules
  home.file.".config/mangowc/window-rules.h.example".text = ''
    // Example MangoWC window rules configuration
    // Add these to your config.h

    static const Rule rules[] = {
        // DMS Components - Always float
        { .title = NULL,    .id = "dms:bar",                     .isfloating = 1 },
        { .title = NULL,    .id = "dms:dock",                    .isfloating = 1 },
        { .title = NULL,    .id = "dms:modal",                   .isfloating = 1 },
        { .title = NULL,    .id = "dms:popout",                  .isfloating = 1 },
        { .title = NULL,    .id = "dms:settings",                .isfloating = 1 },
        { .title = NULL,    .id = "dms:power-menu",              .isfloating = 1 },
        { .title = NULL,    .id = "dms:clipboard",               .isfloating = 1 },
        { .title = NULL,    .id = "dms:spotlight",               .isfloating = 1 },
        { .title = NULL,    .id = "dms:polkit",                  .isfloating = 1 },
        { .title = NULL,    .id = "dms:app-launcher",            .isfloating = 1 },
        { .title = NULL,    .id = "dms:control-center",          .isfloating = 1 },
        { .title = NULL,    .id = "dms:notification-center-popout", .isfloating = 1 },
        { .title = NULL,    .id = "dms:osd",                     .isfloating = 1 },
        { .title = NULL,    .id = "dms:notification",            .isfloating = 1 },
        { .title = NULL,    .id = "dms:tooltip",                 .isfloating = 1 },
        { .title = NULL,    .id = "quickshell",                  .isfloating = 1 },

        // XDG Desktop Portals (file pickers)
        { .title = "^Open.*",  .id = NULL,  .isfloating = 1 },
        { .title = "^Save.*",  .id = NULL,  .isfloating = 1 },

        // Picture-in-Picture
        { .title = "^Picture-in-Picture$",  .id = NULL,  .isfloating = 1 },
        { .title = "^Picture in picture$",  .id = NULL,  .isfloating = 1 },

        // GNOME apps - no client-side decorations
        { .title = NULL,    .id = "^org\\.gnome\\..*",   .noborder = 1 },

        // Media players
        { .title = NULL,    .id = "mpv",                  .isfloating = 1 },
        { .title = NULL,    .id = "jellyfin-desktop",     .isfullscreen = 1 },

        // Image viewers
        { .title = NULL,    .id = "loupe",                .isfloating = 1 },
        { .title = NULL,    .id = "org.gnome.Loupe",      .isfloating = 1 },

        // System utilities
        { .title = NULL,    .id = "org.pulseaudio.pavucontrol", .isfloating = 1 },

        // Calculator
        { .title = NULL,    .id = "org.gnome.Calculator", .isfloating = 1 },
    };
  '';
}
