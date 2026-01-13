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

    services.greetd = mkIf (cfg.displayManager == "greetd") {
      enable = true;
      settings = let
        wmCommands = {
          hyprland = "dms-greeter --command Hyprland";
          niri = "dms-greeter --command niri";
          mangowc = "dms-greeter --command mangowc";
          none = "sh";
        };
        wmCommand = wmCommands.${cfg.windowManager};
      in {
        default_session = {
          command = wmCommand;
          user = "greeter";
        };
        initial_session = mkIf (cfg.windowManager != "none") {
          command = wmCommand;
          inherit (config.my.defaults) user;
        };
      };
    };

    # Create MangoWC configuration file
    environment.etc."greetd/mangowc.conf" = mkIf (cfg.windowManager == "mangowc") {
      text = ''
        # MangoWC greeter configuration
        # Managed by NixOS configuration
      '';
    };

    # DMS-Greeter Manual Sync Configuration
    # Required for proper dms-greeter integration with user sessions
    systemd.tmpfiles.rules = mkIf (cfg.displayManager == "greetd") [
      # Create DMS greeter cache directory
      "d /var/cache/dms-greeter 0755 greeter greeter -"
    ];

    # System activation script to set up DMS greeter symlinks and ACLs
    system.activationScripts.dms-greeter-setup = mkIf (cfg.displayManager == "greetd") {
      text = let
        username = config.my.defaults.user;
        homeDir = "/home/${username}";
      in ''
        # Set ACL permissions on user directories for greeter access
        ${pkgs.acl}/bin/setfacl -m u:greeter:x ${homeDir} || true
        ${pkgs.acl}/bin/setfacl -m u:greeter:x ${homeDir}/.config || true
        ${pkgs.acl}/bin/setfacl -m u:greeter:x ${homeDir}/.local || true
        ${pkgs.acl}/bin/setfacl -m u:greeter:x ${homeDir}/.cache || true
        ${pkgs.acl}/bin/setfacl -m u:greeter:x ${homeDir}/.local/state || true

        # Set group permissions on DMS directories if they exist
        if [ -d "${homeDir}/.config/DankMaterialShell" ]; then
          chgrp -R greeter ${homeDir}/.config/DankMaterialShell || true
          chmod -R g+rX ${homeDir}/.config/DankMaterialShell || true
        fi
        if [ -d "${homeDir}/.local/state/DankMaterialShell" ]; then
          chgrp -R greeter ${homeDir}/.local/state/DankMaterialShell || true
          chmod -R g+rX ${homeDir}/.local/state/DankMaterialShell || true
        fi

        # Create symlinks for DMS greeter configuration sync
        if [ -f "${homeDir}/.config/DankMaterialShell/settings.json" ]; then
          ln -sf ${homeDir}/.config/DankMaterialShell/settings.json \
            /var/cache/dms-greeter/settings.json || true
        fi
        if [ -f "${homeDir}/.local/state/DankMaterialShell/session.json" ]; then
          ln -sf ${homeDir}/.local/state/DankMaterialShell/session.json \
            /var/cache/dms-greeter/session.json || true
        fi
        if [ -f "${homeDir}/.cache/quickshell/dankshell/dms-colors.json" ]; then
          ln -sf ${homeDir}/.cache/quickshell/dankshell/dms-colors.json \
            /var/cache/dms-greeter/colors.json || true
        fi
      '';
    };

    # Add window manager packages
    environment.systemPackages = mkMerge [
      (mkIf cfg.hyprland.enable [pkgs.hyprland])
      (mkIf cfg.niri.enable [pkgs.niri])
      (mkIf cfg.mangowc.enable [pkgs.mangowc])
    ];
  };
}
