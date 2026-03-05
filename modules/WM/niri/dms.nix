_: {
  programs.dank-material-shell = {
    enable = true;
    systemd.enable = false;

    niri = {
      enableSpawn = true;
      enableKeybinds = false; # Using includes instead (more flexible)
      includes = {
        enable = true;
        override = true;
        originalFileName = "hm";
        filesToInclude = [
          "alttab"
          "binds"
          "colors"
          "cursor"
          "layout"
          "outputs"
          "windowrules"
          "wpblur"
        ];
      };
    };

    # Core features
    enableSystemMonitoring = true;
    enableVPN = false;
    enableDynamicTheming = false;
    enableAudioWavelength = false;
    enableCalendarEvents = false; # khal broken in nixpkgs (sphinx-feed)
    settings = {
      # ===== Theme Settings =====
      currentThemeName = "dynamic";
      currentThemeCategory = "dynamic";
      matugenScheme = "scheme-content";

      # ===== Theming Integration =====
      gtkThemingEnabled = true;
      qtThemingEnabled = false;
      syncModeWithPortal = true;
      terminalsAlwaysDark = true;
      runUserMatugenTemplates = true;
      runDmsMatugenTemplates = true;

      # ===== Matugen Templates =====
      matugenTemplateGtk = true;
      matugenTemplateNiri = true;
      matugenTemplateHyprland = false;
      matugenTemplateMangowc = true;
      matugenTemplateQt5ct = true;
      matugenTemplateQt6ct = true;
      matugenTemplateFirefox = true;
      matugenTemplatePywalfox = true;
      matugenTemplateZenBrowser = true;
      matugenTemplateVesktop = true;
      matugenTemplateEquibop = true;
      matugenTemplateGhostty = true;
      matugenTemplateKitty = true;
      matugenTemplateFoot = true;
      matugenTemplateAlacritty = true;
      matugenTemplateNeovim = true;
      matugenTemplateWezterm = true;
      matugenTemplateDgop = true;
      matugenTemplateKcolorscheme = true;
      matugenTemplateVscode = true;
      matugenTemplateEmacs = true;

      # ===== Appearance =====
      popupTransparency = 1;
      dockTransparency = 1;
      widgetBackgroundColor = "sc";
      widgetColorMode = "colorful";
      controlCenterTileColorMode = "primary";
      cornerRadius = 12;
      nightModeEnabled = false;
      customAnimationDuration = 500;

      # ===== Time & Display =====
      use24HourClock = true;
      showSeconds = false;
      useFahrenheit = false;
      windSpeedUnit = "kmh";
      animationSpeed = 1;

      # ===== Wallpaper =====
      wallpaperFillMode = "Fill";
      blurredWallpaperLayer = false;
      blurWallpaperOnOverview = false;

      # ===== Bar Widgets =====
      showLauncherButton = true;
      showWorkspaceSwitcher = true;
      showFocusedWindow = true;
      showWeather = true;
      showMusic = true;
      showClipboard = true;
      showCpuUsage = true;
      showMemUsage = true;
      showCpuTemp = true;
      showGpuTemp = true;
      selectedGpuIndex = 0;
      showSystemTray = true;
      showClock = true;
      showNotificationButton = true;
      showBattery = true;
      showControlCenterButton = true;
      showCapsLockIndicator = true;
      showPrivacyButton = true;
      privacyShowMicIcon = false;
      privacyShowCameraIcon = false;
      privacyShowScreenShareIcon = false;

      # ===== Control Center Icons =====
      controlCenterShowNetworkIcon = true;
      controlCenterShowBluetoothIcon = true;
      controlCenterShowAudioIcon = true;
      controlCenterShowAudioPercent = false;
      controlCenterShowVpnIcon = true;
      controlCenterShowBrightnessIcon = false;
      controlCenterShowBrightnessPercent = false;
      controlCenterShowMicIcon = false;
      controlCenterShowMicPercent = false;
      controlCenterShowBatteryIcon = false;
      controlCenterShowPrinterIcon = false;
      controlCenterShowScreenSharingIcon = true;

      # ===== Control Center Widgets =====
      controlCenterWidgets = [
        {
          id = "volumeSlider";
          enabled = true;
          width = 50;
        }
        {
          id = "brightnessSlider";
          enabled = true;
          width = 50;
        }
        {
          id = "wifi";
          enabled = true;
          width = 50;
        }
        {
          id = "bluetooth";
          enabled = true;
          width = 50;
        }
        {
          id = "audioOutput";
          enabled = true;
          width = 50;
        }
        {
          id = "audioInput";
          enabled = true;
          width = 50;
        }
        {
          id = "nightMode";
          enabled = true;
          width = 50;
        }
        {
          id = "darkMode";
          enabled = true;
          width = 50;
        }
      ];

      # ===== Workspace Settings =====
      showWorkspaceIndex = false;
      showWorkspaceName = false;
      showWorkspacePadding = false;
      workspaceScrolling = false;
      showWorkspaceApps = false;
      maxWorkspaceIcons = 3;
      workspaceAppIconSizeOffset = 0;
      groupWorkspaceApps = true;
      workspaceFollowFocus = false;
      showOccupiedWorkspacesOnly = false;
      reverseScrolling = false;
      workspaceColorMode = "default";
      workspaceOccupiedColorMode = "none";
      workspaceUnfocusedColorMode = "default";
      workspaceUrgentColorMode = "default";
      workspaceFocusedBorderEnabled = false;
      workspaceFocusedBorderColor = "primary";
      workspaceFocusedBorderThickness = 2;

      # ===== Widget Behavior =====
      waveProgressEnabled = true;
      scrollTitleEnabled = true;
      audioVisualizerEnabled = true;
      audioScrollMode = "volume";
      clockCompactMode = false;
      focusedWindowCompactMode = false;
      runningAppsCompactMode = true;
      barMaxVisibleApps = 0;
      barMaxVisibleRunningApps = 0;
      barShowOverflowBadge = true;
      keyboardLayoutNameCompactMode = false;
      runningAppsCurrentWorkspace = false;
      runningAppsGroupByApp = false;
      mediaSize = 1;

      # ===== App ID Substitutions =====
      appIdSubstitutions = [
        {
          pattern = "Spotify";
          replacement = "spotify";
          type = "exact";
        }
        {
          pattern = "beepertexts";
          replacement = "beeper";
          type = "exact";
        }
        {
          pattern = "home assistant desktop";
          replacement = "homeassistant-desktop";
          type = "exact";
        }
        {
          pattern = "com.transmissionbt.transmission";
          replacement = "transmission-gtk";
          type = "contains";
        }
        {
          pattern = "^steam_app_(\\d+)$";
          replacement = "steam_icon_$1";
          type = "regex";
        }
      ];

      # ===== App Launcher =====
      centeringMode = "index";
      appLauncherViewMode = "list";
      spotlightModalViewMode = "list";
      browserPickerViewMode = "grid";
      appPickerViewMode = "grid";
      sortAppsAlphabetically = false;
      appLauncherGridColumns = 4;
      spotlightCloseNiriOverview = true;
      niriOverviewOverlayEnabled = true;
      dankLauncherV2Size = "compact";
      dankLauncherV2BorderEnabled = false;
      dankLauncherV2BorderThickness = 2;
      dankLauncherV2BorderColor = "primary";
      dankLauncherV2ShowFooter = true;

      # ===== Weather =====
      useAutoLocation = false;
      weatherEnabled = true;
      networkPreference = "auto";

      # ===== Fonts =====
      fontFamily = "MesloLGS Nerd Font Mono";
      monoFontFamily = "MesloLGSDZ Nerd Font Mono";
      fontWeight = 700;
      fontScale = 1.07;
      notepadUseMonospace = true;
      notepadFontSize = 14;
      notepadShowLineNumbers = false;
      notepadTransparencyOverride = -1;
      notepadLastCustomTransparency = 0.7;

      # ===== Sounds =====
      soundsEnabled = true;
      useSystemSoundTheme = false;
      soundNewNotification = true;
      soundVolumeChanged = true;
      soundPluggedIn = true;

      # ===== Power Management =====
      acMonitorTimeout = 0;
      acLockTimeout = 0;
      acSuspendTimeout = 0;
      acSuspendBehavior = 0;
      batteryMonitorTimeout = 0;
      batteryLockTimeout = 0;
      batterySuspendTimeout = 0;
      batterySuspendBehavior = 0;
      batteryChargeLimit = 100;

      # ===== Lock Screen =====
      lockBeforeSuspend = false;
      loginctlLockIntegration = true;
      fadeToLockEnabled = true;
      fadeToLockGracePeriod = 5;
      fadeToDpmsEnabled = true;
      fadeToDpmsGracePeriod = 5;
      lockScreenShowPowerActions = true;
      lockScreenShowSystemIcons = true;
      lockScreenShowTime = true;
      lockScreenShowDate = true;
      lockScreenShowProfileImage = true;
      lockScreenShowPasswordField = true;
      lockScreenShowMediaPlayer = true;
      lockScreenPowerOffMonitorsOnLock = false;
      enableFprint = false;
      maxFprintTries = 15;
      lockScreenActiveMonitor = "all";
      lockScreenInactiveColor = "#000000";
      lockScreenNotificationMode = 0;
      hideBrightnessSlider = false;

      # ===== Dock =====
      showDock = false;
      dockAutoHide = false;
      dockSmartAutoHide = false;
      dockGroupByApp = false;
      dockOpenOnOverview = false;
      dockPosition = 1;
      dockSpacing = 4;
      dockBottomGap = 0;
      dockMargin = 0;
      dockIconSize = 40;
      dockIndicatorStyle = "circle";
      dockBorderEnabled = false;
      dockBorderColor = "surfaceText";
      dockBorderOpacity = 1;
      dockBorderThickness = 1;
      dockIsolateDisplays = false;
      dockLauncherEnabled = false;
      dockLauncherLogoMode = "apps";
      dockLauncherLogoCustomPath = "";
      dockLauncherLogoColorOverride = "";
      dockLauncherLogoSizeOffset = 0;
      dockLauncherLogoBrightness = 0.5;
      dockLauncherLogoContrast = 1;
      dockMaxVisibleApps = 0;
      dockMaxVisibleRunningApps = 0;
      dockShowOverflowBadge = true;

      # ===== Notifications =====
      notificationOverlayEnabled = false;
      modalDarkenBackground = true;
      notificationTimeoutLow = 5000;
      notificationTimeoutNormal = 5000;
      notificationTimeoutCritical = 0;
      notificationCompactMode = false;
      notificationPopupPosition = 0;
      notificationHistoryEnabled = true;
      notificationHistoryMaxCount = 50;
      notificationHistoryMaxAgeDays = 7;
      notificationHistorySaveLow = true;
      notificationHistorySaveNormal = true;
      notificationHistorySaveCritical = true;

      # ===== OSD =====
      osdAlwaysShowValue = false;
      osdPosition = 5;
      osdVolumeEnabled = true;
      osdMediaVolumeEnabled = true;
      osdBrightnessEnabled = true;
      osdIdleInhibitorEnabled = true;
      osdMicMuteEnabled = true;
      osdCapsLockEnabled = true;
      osdPowerProfileEnabled = false;
      osdAudioOutputEnabled = true;

      # ===== Power Menu =====
      powerActionConfirm = true;
      powerActionHoldDuration = 0.5;
      powerMenuActions = [
        "reboot"
        "logout"
        "poweroff"
        "lock"
        "suspend"
        "restart"
      ];
      powerMenuDefaultAction = "logout";
      powerMenuGridLayout = false;

      # ===== Display Settings =====
      displayNameMode = "system";
      displayShowDisconnected = false;
      displaySnapToEdge = true;
      displayProfileAutoSelect = false;

      # ===== Bar Configs =====
      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          position = 0;
          screenPreferences = ["all"];
          showOnLastDisplay = true;
          leftWidgets = [
            "launcherButton"
            "workspaceSwitcher"
            "focusedWindow"
          ];
          centerWidgets = [
            "music"
            "clock"
            "weather"
            {
              id = "tailscale";
              enabled = true;
            }
          ];
          rightWidgets = [
            {
              id = "grimblast";
              enabled = true;
            }
            {
              id = "vpn";
              enabled = true;
            }
            {
              id = "dankPomodoroTimer";
              enabled = true;
            }
            {
              id = "dockerManager";
              enabled = true;
            }
            {
              id = "systemTray";
              enabled = true;
            }
            {
              id = "cpuUsage";
              enabled = true;
            }
            {
              id = "memUsage";
              enabled = true;
            }
            {
              id = "notificationButton";
              enabled = true;
            }
            {
              id = "controlCenterButton";
              enabled = true;
            }
            {
              id = "powerMenuButton";
              enabled = true;
            }
          ];
          spacing = 4;
          innerPadding = 4;
          bottomGap = -5;
          transparency = 1;
          widgetTransparency = 1;
          squareCorners = false;
          noBackground = false;
          gothCornersEnabled = false;
          gothCornerRadiusOverride = false;
          gothCornerRadiusValue = 12;
          borderEnabled = false;
          borderColor = "surfaceText";
          borderOpacity = 1;
          borderThickness = 1;
          fontScale = 1.19;
          autoHide = false;
          autoHideDelay = 250;
          openOnOverview = false;
          visible = true;
          popupGapsAuto = true;
          popupGapsManual = 4;
          scrollYBehavior = "none";
        }
      ];

      # ===== Cursor Settings =====
      cursorSettings = {
        theme = "Bibata-Modern-Classic";
        size = 24;
        niri = {
          hideWhenTyping = false;
          hideAfterInactiveMs = 0;
        };
      };

      # ===== Launcher Logo =====
      launcherLogoMode = "os";
      launcherLogoColorOverride = "surface";
      launcherLogoColorInvertOnMode = false;
      launcherLogoBrightness = 0.5;
      launcherLogoContrast = 1;
      launcherLogoSizeOffset = 3;

      # ===== Desktop Clock =====
      desktopClockEnabled = false;
      desktopClockStyle = "analog";
      desktopClockTransparency = 0.8;
      desktopClockColorMode = "primary";
      desktopClockShowDate = true;
      desktopClockShowAnalogNumbers = false;
      desktopClockShowAnalogSeconds = true;
      desktopClockX = -1;
      desktopClockY = -1;
      desktopClockWidth = 280;
      desktopClockHeight = 180;
      desktopClockDisplayPreferences = ["all"];

      # ===== System Monitor =====
      systemMonitorEnabled = false;
      systemMonitorShowHeader = true;
      systemMonitorTransparency = 0.8;
      systemMonitorColorMode = "primary";
      systemMonitorShowCpu = true;
      systemMonitorShowCpuGraph = true;
      systemMonitorShowCpuTemp = true;
      systemMonitorShowGpuTemp = false;
      systemMonitorShowMemory = true;
      systemMonitorShowMemoryGraph = true;
      systemMonitorShowNetwork = true;
      systemMonitorShowNetworkGraph = true;
      systemMonitorShowDisk = true;
      systemMonitorShowTopProcesses = false;
      systemMonitorTopProcessCount = 3;
      systemMonitorTopProcessSortBy = "cpu";
      systemMonitorGraphInterval = 60;
      systemMonitorLayoutMode = "auto";
      systemMonitorX = -1;
      systemMonitorY = -1;
      systemMonitorWidth = 320;
      systemMonitorHeight = 480;
      systemMonitorDisplayPreferences = ["all"];

      # ===== Plugin Settings =====
      builtInPluginSettings = {
        dms_settings_search = {
          trigger = "?";
        };
      };

      configVersion = 5;
    };
  };
}
