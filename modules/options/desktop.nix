{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.desktop;
in {
  options.my.desktop = {
    # =================================================================
    # Window Manager / Desktop Environment Selection
    # =================================================================
    windowManager = mkOption {
      type = types.enum [
        "hyprland"
        "niri"
        "none"
      ];
      default = "none";
      description = ''
        Which window manager to use as the default session.
        - hyprland: Hyprland with DMS (start-hyprland)
        - niri: Niri with systemd integration (niri-session)
        - none: No window manager configured
      '';
    };

    desktopEnvironment = mkOption {
      type = types.enum [
        "kde"
        "gnome"
        "none"
      ];
      default = "none";
      description = ''
        Which desktop environment to use.
        - kde: KDE Plasma
        - gnome: GNOME
        - none: No desktop environment (window manager only)
      '';
    };

    # =================================================================
    # Individual Component Enables
    # =================================================================
    hyprland = {
      enable = mkEnableOption "Hyprland window manager";
    };

    niri = {
      enable = mkEnableOption "Niri scrollable-tiling compositor";
    };


    kde = {
      enable = mkEnableOption "KDE Plasma desktop environment";
    };

    gnome = {
      enable = mkEnableOption "GNOME desktop environment";
    };

    # =================================================================
    # DMS (DankMaterialShell) Configuration
    # =================================================================
    dms = {
      enable = mkEnableOption "DankMaterialShell integration";

      features = {
        systemMonitoring = mkOption {
          type = types.bool;
          default = true;
          description = "Enable system monitoring widgets (dgop)";
        };

        clipboard = mkOption {
          type = types.bool;
          default = true;
          description = "Enable clipboard history manager";
        };

        vpn = mkOption {
          type = types.bool;
          default = false;
          description = "Enable VPN management widget";
        };

        dynamicTheming = mkOption {
          type = types.bool;
          default = true;
          description = "Enable wallpaper-based theming (matugen)";
        };

        audioWavelength = mkOption {
          type = types.bool;
          default = false;
          description = "Enable audio visualizer (cava)";
        };

        calendarEvents = mkOption {
          type = types.bool;
          default = true;
          description = "Enable calendar integration (khal)";
        };
      };
    };

    # =================================================================
    # Display Manager Configuration
    # =================================================================
    displayManager = mkOption {
      type = types.enum [
        "greetd"
        "sddm"
        "gdm"
        "none"
      ];
      default = "greetd";
      description = ''
        Which display manager to use for login.
        - greetd: Minimal TTY-based display manager (with tuigreet)
        - sddm: Simple Desktop Display Manager (KDE default)
        - gdm: GNOME Display Manager
        - none: No display manager (startx/manual login)
      '';
    };
  };

  # =================================================================
  # Configuration Implementation
  # =================================================================
  config = mkIf (cfg.windowManager != "none" || cfg.desktopEnvironment != "none") {
    # Auto-enable components based on windowManager selection
    my.desktop.hyprland.enable = mkDefault (cfg.windowManager == "hyprland");
    my.desktop.niri.enable = mkDefault (cfg.windowManager == "niri");

    # Auto-enable DEs based on desktopEnvironment selection
    my.desktop.kde.enable = mkDefault (cfg.desktopEnvironment == "kde");
    my.desktop.gnome.enable = mkDefault (cfg.desktopEnvironment == "gnome");

    # Add window manager packages
    environment.systemPackages = mkMerge [
      (mkIf cfg.hyprland.enable [pkgs.hyprland])
      (mkIf cfg.niri.enable [pkgs.niri])
    ];

    # Configure DMS greeter for greetd
    programs.dank-material-shell.greeter = mkIf (cfg.displayManager == "greetd" && (cfg.windowManager == "hyprland" || cfg.windowManager == "niri")) {
      enable = true;
      compositor.name = cfg.windowManager;
      configHome = "/home/${config.my.defaults.user}";
      compositor.customConfig = mkIf (cfg.windowManager == "niri") ''
        output "DP-4" {
          mode 3840x2160@60
          position 0 0
          scale 2.0
        }

        output "DP-5" {
          mode 3840x2160@60
          position 1920 0
          scale 2.0
        }
      '';
    };
  };
}
