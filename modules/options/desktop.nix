{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.my.desktop;
  dmsShell = inputs.dms.packages.${pkgs.system}.dms-shell;
in {
  options.my.desktop = {
    # =================================================================
    # Window Manager / Desktop Environment Selection
    # =================================================================
    windowManager = mkOption {
      type = types.enum [
        "hyprland"
        "niri"
        "mangowc"
        "none"
      ];
      default = "none";
      description = ''
        Which window manager to use as the default session.
        - hyprland: Hyprland with DMS (start-hyprland)
        - niri: Niri with systemd integration (niri-session)
        - mangowc: MangoWC compositor (mangowc)
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

    mangowc = {
      enable = mkEnableOption "MangoWC (dwl-based) compositor";
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
    my.desktop.mangowc.enable = mkDefault (cfg.windowManager == "mangowc");

    # Auto-enable DEs based on desktopEnvironment selection
    my.desktop.kde.enable = mkDefault (cfg.desktopEnvironment == "kde");
    my.desktop.gnome.enable = mkDefault (cfg.desktopEnvironment == "gnome");

    # DankMaterialShell Greeter configuration for niri, hyprland, sway
    programs.dank-material-shell.greeter = mkIf (cfg.displayManager == "greetd" && elem cfg.windowManager ["niri" "hyprland" "sway"]) {
      enable = true;
      compositor.name = cfg.windowManager;
      configHome = "/home/${config.my.defaults.user}";
    };

    # Manual greetd configuration for mangowc with dms-greeter
    services.greetd = mkIf (cfg.displayManager == "greetd" && cfg.windowManager == "mangowc") {
      enable = true;
      settings = {
        default_session = {
          command = let
            quickshell = inputs.dms.packages.${pkgs.system}.quickshell;
            greeterScript = pkgs.writeShellScript "dms-greeter-mangowc" ''
              export PATH=$PATH:${lib.makeBinPath [quickshell pkgs.mangowc]}
              exec sh ${dmsShell}/share/dms/assets/dms-greeter \
                --cache-dir /var/lib/dms-greeter \
                --command mangowc \
                -C /etc/greetd/mangowc.conf \
                -p ${dmsShell}/share/quickshell/dms
            '';
          in toString greeterScript;
          user = "greeter";
        };
      };
    };

    # Create MangoWC configuration file for greeter
    environment.etc."greetd/mangowc.conf" = mkIf (cfg.displayManager == "greetd" && cfg.windowManager == "mangowc") {
      text = ''
        # MangoWC greeter configuration
        # Managed by NixOS configuration
      '';
    };

    # Setup cache directory and config sync for mangowc greeter
    systemd.tmpfiles.settings."10-dmsgreeter-mangowc" = mkIf (cfg.displayManager == "greetd" && cfg.windowManager == "mangowc") {
      "/var/lib/dms-greeter".d = {
        user = "greeter";
        group = "greeter";
        mode = "0750";
      };
    };

    systemd.services.greetd.preStart = mkIf (cfg.displayManager == "greetd" && cfg.windowManager == "mangowc") (
      let
        username = config.my.defaults.user;
        configHome = "/home/${username}";
      in ''
        cd /var/lib/dms-greeter

        # Copy DMS config files if they exist
        [ -f "${configHome}/.config/DankMaterialShell/settings.json" ] && \
          cp "${configHome}/.config/DankMaterialShell/settings.json" . || true
        [ -f "${configHome}/.local/state/DankMaterialShell/session.json" ] && \
          cp "${configHome}/.local/state/DankMaterialShell/session.json" . || true
        [ -f "${configHome}/.cache/DankMaterialShell/dms-colors.json" ] && \
          cp "${configHome}/.cache/DankMaterialShell/dms-colors.json" colors.json || true

        chown greeter: * || true
      ''
    );


    # Add window manager packages
    environment.systemPackages = mkMerge [
      (mkIf cfg.hyprland.enable [pkgs.hyprland])
      (mkIf cfg.niri.enable [pkgs.niri])
      (mkIf cfg.mangowc.enable [pkgs.mangowc])
    ];
  };
}
