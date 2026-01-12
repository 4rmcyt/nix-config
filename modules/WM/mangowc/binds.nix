_: {
  # ============================================
  # MANGOWC KEYBINDINGS
  # ============================================
  # Note: MangoWC is based on dwl/wlroots and uses a config.h file for keybindings.
  # This file documents the recommended keybindings for DMS integration.
  # You'll need to configure these in MangoWC's config.h or config file.

  # Documentation of recommended keybindings for MangoWC + DMS integration
  home.file.".config/mangowc/keybinds.md".text = ''
    # MangoWC + DMS Keybindings

    Configure these in your MangoWC config.h or config file.

    ## APPLICATIONS
    - `Mod+Return` - Terminal (wezterm)
    - `Mod+B` - Browser (chromium)
    - `Mod+E` - File Manager (nautilus)
    - `Mod+Space` - DMS Application Launcher (quickshell -m dms.overview)
    - `Mod+D` - Fallback Launcher (walker)
    - `Ctrl+Shift+Escape` - Task Manager (quickshell -m dms.taskmgr)
    - `Mod+M` - DMS Task Manager
    - `Mod+,` - DMS Settings (quickshell -m dms.settings)
    - `Mod+Shift+D` - Discord

    ## WINDOW MANAGEMENT
    - `Mod+Q` - Close window
    - `Mod+F` - Toggle fullscreen
    - `Mod+Shift+Space` - Toggle floating

    ## SYSTEM CONTROLS
    - `Mod+Escape` - Lock screen (swaylock)
    - `Mod+Shift+Escape` - Power menu (dms ipc call modal toggle power-menu)
    - `Mod+N` - Notifications (dms ipc call modal toggle notifications)
    - `Mod+/` - Keybinds cheatsheet (dms ipc call keybinds toggle mangowc)
    - `Mod+Shift+N` - Toggle night mode (dms ipc call night-mode toggle)

    ## THEMING & CUSTOMIZATION
    - `Mod+C` - Color picker (dms ipc call modal toggle color-picker)
    - `Mod+W` - Wallpaper selector (dms ipc call modal toggle dashboard)

    ## SCREENSHOTS - DMS CLI
    - `Print` - Region screenshot (dms screenshot)
    - `Mod+Print` - Full screen screenshot (dms screenshot full)
    - `Mod+Shift+Print` - All displays screenshot (dms screenshot all)
    - `Ctrl+Print` - Screenshot to clipboard only (dms screenshot --no-file)

    ## FOCUS CONTROL
    - `Alt+Tab` - Window switcher (quickshell -m dms.alttab)

    ## MEDIA CONTROLS - DMS IPC
    - `XF86AudioPlay` - Play/Pause (dms ipc call media play-pause)
    - `XF86AudioNext` - Next track (dms ipc call media next)
    - `XF86AudioPrev` - Previous track (dms ipc call media previous)
    - `XF86AudioStop` - Stop playback (dms ipc call media stop)
    - `XF86AudioRaiseVolume` - Volume up (dms ipc call audio volume-increment 5)
    - `XF86AudioLowerVolume` - Volume down (dms ipc call audio volume-decrement 5)
    - `XF86AudioMute` - Toggle mute (dms ipc call audio volume-toggle-mute)
    - `XF86MonBrightnessUp` - Brightness up (dms ipc call brightness increment 5)
    - `XF86MonBrightnessDown` - Brightness down (dms ipc call brightness decrement 5)

    ## CLIPBOARD - DMS Integration
    - `Mod+V` - Clipboard history (dms ipc call modal toggle clipboard)
  '';

  # Example config.h snippet for reference
  home.file.".config/mangowc/config.h.example".text = ''
    // Example MangoWC config.h keybindings for DMS integration
    // Copy these to your actual MangoWC config.h

    #define MODKEY Mod4Mask  // Super key

    static const Key keys[] = {
        // Applications
        { MODKEY,              XK_Return,     spawn,          SHCMD("wezterm start --cwd .") },
        { MODKEY,              XK_b,          spawn,          SHCMD("chromium") },
        { MODKEY,              XK_e,          spawn,          SHCMD("nautilus") },
        { MODKEY,              XK_space,      spawn,          SHCMD("quickshell -m dms.overview") },
        { MODKEY,              XK_d,          spawn,          SHCMD("walker") },
        { MODKEY|ShiftMask,    XK_d,          spawn,          SHCMD("discord --enable-features=UseOzonePlatform --ozone-platform=wayland") },

        // System
        { MODKEY,              XK_comma,      spawn,          SHCMD("quickshell -m dms.settings") },
        { MODKEY,              XK_m,          spawn,          SHCMD("quickshell -m dms.taskmgr") },
        { MODKEY,              XK_n,          spawn,          SHCMD("dms ipc call modal toggle notifications") },
        { MODKEY|ShiftMask,    XK_n,          spawn,          SHCMD("dms ipc call night-mode toggle") },
        { MODKEY|ShiftMask,    XK_Escape,     spawn,          SHCMD("dms ipc call modal toggle power-menu") },
        { MODKEY,              XK_Escape,     spawn,          SHCMD("swaylock") },

        // Screenshots
        { 0,                   XK_Print,      spawn,          SHCMD("dms screenshot") },
        { MODKEY,              XK_Print,      spawn,          SHCMD("dms screenshot full") },
        { MODKEY|ShiftMask,    XK_Print,      spawn,          SHCMD("dms screenshot all") },

        // Theming
        { MODKEY,              XK_c,          spawn,          SHCMD("dms ipc call modal toggle color-picker") },
        { MODKEY,              XK_w,          spawn,          SHCMD("dms ipc call modal toggle dashboard") },
        { MODKEY,              XK_v,          spawn,          SHCMD("dms ipc call modal toggle clipboard") },

        // Window management
        { MODKEY,              XK_q,          killclient,     {0} },
        { MODKEY,              XK_f,          togglefullscreen, {0} },
        { MODKEY|ShiftMask,    XK_space,      togglefloating, {0} },

        // Media keys
        { 0, XF86XK_AudioPlay,        spawn, SHCMD("dms ipc call media play-pause") },
        { 0, XF86XK_AudioNext,        spawn, SHCMD("dms ipc call media next") },
        { 0, XF86XK_AudioPrev,        spawn, SHCMD("dms ipc call media previous") },
        { 0, XF86XK_AudioRaiseVolume, spawn, SHCMD("dms ipc call audio volume-increment 5") },
        { 0, XF86XK_AudioLowerVolume, spawn, SHCMD("dms ipc call audio volume-decrement 5") },
        { 0, XF86XK_AudioMute,        spawn, SHCMD("dms ipc call audio volume-toggle-mute") },
        { 0, XF86XK_MonBrightnessUp,  spawn, SHCMD("dms ipc call brightness increment 5") },
        { 0, XF86XK_MonBrightnessDown,spawn, SHCMD("dms ipc call brightness decrement 5") },
    };
  '';
}
