{
  config,
  lib,
  pkgs,
  ...
}:

{

  home.packages = [
    pkgs.hicolor-icon-theme
    pkgs.adwaita-icon-theme
    pkgs.quickshell # Ensure qs command is available in PATH
  ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
    

    settings = [
      {
        appLauncher = {
          enableClipboardHistory = true;
        };

        # ui = {
        #   fontDefault = config.stylix.fonts.sansSerif.name;
        #   fontFixed = config.stylix.fonts.monospace.name;
        # };

        nightLight = {
          enabled = true;
          autoSchedule = true;
          dayTemp = "6500";
          nightTemp = "4000";
        };

        general = {
          lockOnSuspend = true;
          avatarImage = "~/Pictures/face.jpg";
        };

        dock = {
          enabled = false;
        };

        bar = {
          floating = true;
          marginHorizontal = 0.25;
          marginVertical = 0.25;
          widgets = {
            left = [
              {
                id = "Workspace";
                characterCount = 2;
              }
            ];
            center = [
              {
                id = "Clock";
                formatHorizontal = "HH:mm:ss ddd, MMM dd";
                usePrimaryColor = true;
              }
              {
                id = "KeepAwake";
              }
            ];
            right = [
              [
                {
                  id = "Tray";
                }
                {
                  id = "NotificationHistory";
                  hideWhenZero = true;
                }
              ]
              {
                id = "WiFi";
                displayMode = "icon";
              }
              {
                id = "Bluetooth";
                displayMode = "icon";
              }
              {
                id = "Brightness";
                displayMode = "onhover";
              }
              {
                id = "Battery";
              }
              [
                {
                  id = "Volume";
                  displayMode = "onhover";
                }
                {
                  id = "ControlCenter";
                  icon = "noctalia";
                }
              ]
            ];
          };
        };

        wallpaper = {
          directory = "~/Pictures/Wallpapers";
          overviewEnabled = true;
        };

        location = {
          name = "calgary";
          showCalendarWeather = true;
        };

        calendar = {
          cards = [
            {
              enabled = true;
              id = "calendar-header-card";
            }
            {
              enabled = true;
              id = "calendar-month-card";
            }
            {
              enabled = false;
              id = "timer-card";
            }
            {
              enabled = true;
              id = "weather-card";
            }
          ];
        };



        controlCenter = {
          shortcuts = {
            left =  [
              [
                { id = "WiFi"; }
                { id = "Bluetooth"; }
              ]
              [
                { id = "ScreenRecorder"; }
                { id = "WallpaperSelector"; }
              ]
            ];
            right = [
               [
                { id = "PowerProfile"; }
              ]
              [
                { id = "Notifications"; }
                { id = "KeepAwake"; }
                { id = "NightLight"; }
              ]
            ];
          };
        };
      }
    ];
  };
}
