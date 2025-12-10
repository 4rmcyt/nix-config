{pkgs, ...}: {
  # Session variables for Wayland support
  home.sessionVariables = {
    # Wayland Support
    NIXOS_OZONE_WL = "1";
    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";

    # Browser Optimization
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  # KDE packages at user level
  home.packages = with pkgs; [
    # KDE Applications
    kdePackages.ark
    kdePackages.breeze
    kdePackages.discover
    kdePackages.filelight
    kdePackages.gwenview
    kdePackages.kcalc
    kdePackages.kcharselect
    kdePackages.kclock
    kdePackages.kfind
    kdePackages.kgpg
    kdePackages.kio-extras
    kdePackages.konsole
    kdePackages.ksystemlog
    kdePackages.kate
    kdePackages.okular
    kdePackages.partitionmanager
    kdePackages.plasma-browser-integration
    kdePackages.plasma-pa
    kdePackages.qtmultimedia
    kdePackages.qtsvg
    kdePackages.sddm-kcm
    kdePackages.signon-kwallet-extension
    kdePackages.spectacle
    kdePackages.systemsettings
    kwalletcli
    kdePackages.qtwayland
    libsForQt5.qt5.qtwayland
    kdePackages.dolphin
    tail-tray

    # SDDM Themes (for configuration via GUI)
    sddm-astronaut
    sddm-sugar-dark

    # KDE Portal Support
    libdbusmenu

    # KDE Themes and Icons
    gruvbox-dark-icons-gtk
    gruvbox-material-gtk-theme
    gruvbox-plus-icons
    kde-gruvbox
    plasma-panel-colorizer
    crystal-dock

    # Qt/KDE Support Packages
    pinentry-qt
    ibus-with-plugins
  ];

  programs.plasma = {
    enable = true;

    # Keyboard Shortcuts
    shortcuts = {
      # KDE Keyboard Layout Switcher
      "KDE Keyboard Layout Switcher"."Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Alt+K";

      # Accessibility
      kaccess."Toggle Screen Reader On and Off" = "Meta+Alt+S";

      # Audio Controls
      kmix.decrease_microphone_volume = "Microphone Volume Down";
      kmix.decrease_volume = "Volume Down";
      kmix.decrease_volume_small = "Shift+Volume Down";
      kmix.increase_microphone_volume = "Microphone Volume Up";
      kmix.increase_volume = "Volume Up";
      kmix.increase_volume_small = "Shift+Volume Up";
      kmix.mic_mute = ["Microphone Mute" "Meta+Volume Mute"];
      kmix.mute = "Volume Mute";

      # Session Management
      ksmserver."Lock Session" = ["Meta+L" "Screensaver"];
      ksmserver."Log Out" = "Ctrl+Alt+Del";

      # KWin Window Management
      kwin."Activate Window Demanding Attention" = "Meta+Ctrl+A";
      kwin."Edit Tiles" = "Meta+T";
      kwin.Expose = "Ctrl+F9";
      kwin.ExposeAll = ["Ctrl+F10" "Launch (C)"];
      kwin.ExposeClass = "Ctrl+F7";
      kwin."Grid View" = "Meta+G";
      kwin."Kill Window" = "Meta+Ctrl+Esc";
      kwin.MoveMouseToCenter = "Meta+F6";
      kwin.MoveMouseToFocus = "Meta+F5";
      kwin.Overview = "Meta+W";
      kwin."Show Desktop" = "Meta+D";

      # Desktop Navigation
      kwin."Switch One Desktop Down" = "Meta+Ctrl+Down";
      kwin."Switch One Desktop Left" = "Meta+Ctrl+Left";
      kwin."Switch One Desktop Right" = "Meta+Ctrl+Right";
      kwin."Switch One Desktop Up" = "Meta+Ctrl+Up";
      kwin."Switch to Desktop 1" = "Ctrl+F1";
      kwin."Switch to Desktop 2" = "Ctrl+F2";
      kwin."Switch to Desktop 3" = "Ctrl+F3";
      kwin."Switch to Desktop 4" = "Ctrl+F4";

      # Window Navigation
      kwin."Switch Window Down" = "Meta+Alt+Down";
      kwin."Switch Window Left" = "Meta+Alt+Left";
      kwin."Switch Window Right" = "Meta+Alt+Right";
      kwin."Switch Window Up" = "Meta+Alt+Up";
      kwin."Walk Through Windows" = ["Meta+Tab" "Alt+Tab"];
      kwin."Walk Through Windows (Reverse)" = ["Meta+Shift+Tab" "Alt+Shift+Tab"];
      kwin."Walk Through Windows of Current Application" = ["Meta+`" "Alt+`"];
      kwin."Walk Through Windows of Current Application (Reverse)" = ["Meta+~" "Alt+~"];

      # Window Actions
      kwin."Window Close" = "Alt+F4";
      kwin."Window Maximize" = "Meta+PgUp";
      kwin."Window Minimize" = "Meta+PgDown";
      kwin."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
      kwin."Window One Desktop Left" = "Meta+Ctrl+Shift+Left";
      kwin."Window One Desktop Right" = "Meta+Ctrl+Shift+Right";
      kwin."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
      kwin."Window Operations Menu" = "Alt+F3";
      kwin."Window Quick Tile Bottom" = "Meta+Down";
      kwin."Window Quick Tile Left" = "Meta+Left";
      kwin."Window Quick Tile Right" = "Meta+Right";
      kwin."Window Quick Tile Top" = "Meta+Up";
      kwin."Window to Next Screen" = "Meta+Shift+Right";
      kwin."Window to Previous Screen" = "Meta+Shift+Left";
      kwin.disableInputCapture = "Meta+Shift+Esc";

      # Zoom
      kwin.view_actual_size = "Meta+0";
      kwin.view_zoom_in = ["Meta++" "Meta+="];
      kwin.view_zoom_out = "Meta+-";

      # Media Controls
      mediacontrol.nextmedia = "Media Next";
      mediacontrol.pausemedia = "Media Pause";
      mediacontrol.playpausemedia = "Media Play";
      mediacontrol.previousmedia = "Media Previous";
      mediacontrol.stopmedia = "Media Stop";

      # Power Management
      org_kde_powerdevil."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
      org_kde_powerdevil."Decrease Screen Brightness" = "Monitor Brightness Down";
      org_kde_powerdevil."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
      org_kde_powerdevil.Hibernate = "Hibernate";
      org_kde_powerdevil."Increase Keyboard Brightness" = "Keyboard Brightness Up";
      org_kde_powerdevil."Increase Screen Brightness" = "Monitor Brightness Up";
      org_kde_powerdevil."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
      org_kde_powerdevil.PowerDown = "Power Down";
      org_kde_powerdevil.PowerOff = "Power Off";
      org_kde_powerdevil.Sleep = "Sleep";
      org_kde_powerdevil."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
      org_kde_powerdevil.powerProfile = ["Battery" "Meta+B"];

      # Plasma Shell
      plasmashell."activate application launcher" = ["Meta" "Alt+F1"];
      plasmashell."activate task manager entry 1" = "Meta+1";
      plasmashell."activate task manager entry 2" = "Meta+2";
      plasmashell."activate task manager entry 3" = "Meta+3";
      plasmashell."activate task manager entry 4" = "Meta+4";
      plasmashell."activate task manager entry 5" = "Meta+5";
      plasmashell."activate task manager entry 6" = "Meta+6";
      plasmashell."activate task manager entry 7" = "Meta+7";
      plasmashell."activate task manager entry 8" = "Meta+8";
      plasmashell."activate task manager entry 9" = "Meta+9";
      plasmashell.clipboard_action = "Meta+Ctrl+X";
      plasmashell.cycle-panels = "Meta+Alt+P";
      plasmashell."manage activities" = "Meta+Q";
      plasmashell."next activity" = "Meta+A";
      plasmashell."previous activity" = "Meta+Shift+A";
      plasmashell."show dashboard" = "Ctrl+F12";
      plasmashell.show-on-mouse-pos = "Meta+V";
    };

    # Panels configuration
    panels = [
      # Top panel - Screen 0
      {
        location = "top";
        screen = 0;
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.pager"
          {
            name = "org.kde.plasma.icontasks";
            config.General.launchers = [
              "applications:systemsettings.desktop"
              "preferred://filemanager"
              "applications:org.wezfurlong.wezterm.desktop"
              "applications:code-url-handler.desktop"
              "applications:chromium-browser.desktop"
            ];
          }
          "org.kde.plasma.marginsseparator"
          {
            systemTray.items.shown = [
              "org.kde.plasma.battery"
              "org.kde.plasma.bluetooth"
              "org.kde.plasma.brightness"
              "org.kde.plasma.clipboard"
              "org.kde.plasma.keyboardlayout"
              "org.kde.plasma.mediacontroller"
              "org.kde.plasma.networkmanagement"
              "org.kde.plasma.notifications"
              "org.kde.plasma.volume"
              "org.kde.plasma.weather"
            ];
          }
          "org.kde.plasma.digitalclock"
          "org.kde.plasma.showdesktop"
        ];
      }
      # Top panel - Screen 1
      {
        location = "top";
        screen = 1;
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.pager"
          {
            name = "org.kde.plasma.icontasks";
            config.General.launchers = [
              "applications:systemsettings.desktop"
              "preferred://filemanager"
              "applications:org.wezfurlong.wezterm.desktop"
              "applications:chromium-browser.desktop"
              "applications:code-url-handler.desktop"
              "applications:com.ayugram.desktop.desktop"
            ];
          }
          "org.kde.plasma.marginsseparator"
          {
            systemTray.items.shown = [
              "org.kde.plasma.battery"
              "org.kde.plasma.bluetooth"
              "org.kde.plasma.brightness"
              "org.kde.plasma.clipboard"
              "org.kde.plasma.keyboardlayout"
              "org.kde.plasma.mediacontroller"
              "org.kde.plasma.networkmanagement"
              "org.kde.plasma.notifications"
              "org.kde.plasma.volume"
              "org.kde.plasma.weather"
            ];
          }
          "org.kde.plasma.digitalclock"
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    # Workspace settings
    workspace = {
      colorScheme = "Layan";
      cursor.theme = "breeze_cursors";
      wallpaperSlideShow = {
        path = "/home/zeev/Pictures/Wallpapers";
        interval = 3600; # Change wallpaper every 1 hour (3600 seconds)
      };
    };

    # KDE Configuration Files
    configFile = {
      baloofilerc."Basic Settings" = {
        Indexing-Enabled = false;
      };
      baloofilerc.General = {
        dbVersion = 2;
        "exclude filters" = "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
        "exclude filters version" = 9;
      };

      # Dolphin
      dolphinrc.General.ViewPropsTimestamp = "2025,11,28,11,26,42.35";
      dolphinrc."KFileDialog Settings" = {
        "Places Icons Auto-resize" = false;
        "Places Icons Static Size" = 22;
      };

      # Activity Manager
      kactivitymanagerdrc.activities."6bd6c641-b94e-4733-8eed-7438f51c6bed" = "Default";
      kactivitymanagerdrc.main.currentActivity = "6bd6c641-b94e-4733-8eed-7438f51c6bed";

      # Kate
      katerc.General = {
        "Days Meta Infos" = 30;
        "Save Meta Infos" = true;
        "Show Full Path in Title" = false;
        "Show Menu Bar" = true;
        "Show Status Bar" = true;
        "Show Tab Bar" = true;
        "Show Url Nav Bar" = true;
      };
      katerc.filetree = {
        editShade = "126,68,114";
        listMode = false;
        middleClickToClose = false;
        shadingEnabled = true;
        showCloseButton = false;
        showFullPathOnRoots = false;
        showToolbar = true;
        sortRole = 0;
        viewShade = "124,42,140";
      };

      # KDE Daemon
      kded5rc.Module-browserintegrationreminder.autoload = false;
      kded5rc.Module-device_automounter.autoload = false;

      # Global KDE settings
      kdeglobals.Icons.Theme = "Gruvbox-Plus-Dark";

      # Cursor theme configuration
      kcminputrc.Mouse.cursorTheme = "breeze_cursors";
      kdeglobals."KFileDialog Settings" = {
        "Allow Expansion" = false;
        "Automatically select filename extension" = true;
        "Breadcrumb Navigation" = true;
        "Decoration position" = 2;
        "Show Full Path" = false;
        "Show Inline Previews" = true;
        "Show Preview" = false;
        "Show Speedbar" = true;
        "Show hidden files" = false;
        "Sort by" = "Name";
        "Sort directories first" = true;
        "Sort hidden files last" = false;
        "Sort reversed" = false;
        "Speedbar Width" = 140;
        "View Style" = "DetailTree";
      };
      kdeglobals.WM = {
        activeBackground = "54,56,62";
        activeBlend = "59,62,68";
        activeForeground = "221,221,221";
        inactiveBackground = "62,65,71";
        inactiveBlend = "67,71,77";
        inactiveForeground = "120,120,120";
      };

      # KIO
      kiorc.Confirmations.ConfirmDelete = true;

      # KSplash
      ksplashrc.KSplash.Theme = "Ant-Dark";

      # KWallet
      kwalletrc.Wallet = {
        "Close When Idle" = false;
        "Close on Screensaver" = false;
        "Default Wallet" = "kdewallet";
        Enabled = true;
        "First Use" = false;
        "Idle Timeout" = 10;
        "Launch Manager" = true;
        "Leave Manager Open" = false;
        "Leave Open" = true;
        "Prompt on Open" = false;
        "Use One Wallet" = true;
      };
      kwalletrc."org.freedesktop.secrets".apiEnabled = true;

      # KWin
      kwinrc.Desktops = {
        Id_1 = "e4961df9-b1c6-45e0-a909-bc04f57ae456";
        Number = 1;
        Rows = 1;
      };
      kwinrc.Tiling.padding = 4;
      kwinrc."Tiling/e4961df9-b1c6-45e0-a909-bc04f57ae456/ae54fcef-1a61-4c5d-8e94-9157e55af1be".tiles = ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      kwinrc."Tiling/e4961df9-b1c6-45e0-a909-bc04f57ae456/dfc3ea77-365f-4b09-bb91-ee25371552bd".tiles = ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      kwinrc.Xwayland.Scale = 2.1;
      kwinrc."org.kde.kdecoration2" = {
        BorderSize = "Tiny";
        BorderSizeAuto = false;
        theme = "__aurorae__svg__Ant-Dark";
      };
      # Window Switcher configuration
      kwinrc.TabBox = {
        LayoutName = "org.kde.breeze.desktop";
      };
      kwinrc.TabBoxAlternative = {
        LayoutName = "org.kde.breeze.desktop";
      };

      # Locale
      plasma-localerc.Formats.LANG = "en_US.UTF-8";

      # Notifications
      plasmanotifyrc."Applications/com.ayugram.desktop".Seen = true;
      plasmanotifyrc."Applications/thunderbird".Seen = true;

      # Wallpapers
      plasmarc.Wallpapers.usersWallpapers = "/home/zeev/Pictures/Wallpapers/ColorWall-eolmrl.jpg,/home/zeev/Pictures/Wallpapers/ColorWall-kwd36d.jpg,/home/zeev/Pictures/Wallpapers/scorched_earth_art-wallpaper-3840x2160.jpg,/home/zeev/Pictures/Wallpapers/spring_blooms_beneath_the_glow_of_a_pink_moon-wallpaper-3840x2160.jpg";
    };
  };
}
