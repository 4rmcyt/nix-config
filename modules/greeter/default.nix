{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.my.desktop;
  system = pkgs.stdenv.hostPlatform.system;
  dmsShell = inputs.dms.packages.${system}.default;
  quickshell = inputs.quickshell.packages.${system}.default or pkgs.quickshell;
in {
  config = mkIf (cfg.displayManager == "greetd" && cfg.windowManager != "none") {
    # DankMaterialShell Greeter configuration for niri and hyprland
    # These use the official greeter module which supports them natively
    programs.dank-material-shell.greeter = mkIf (elem cfg.windowManager ["niri" "hyprland"]) {
      enable = true;
      compositor.name = cfg.windowManager;
      configHome = "/home/${config.my.defaults.user}";
    };

    # Manual greetd configuration for mangowc using dms-greeter
    # MangoWC is not in the greeter module's enum, so we configure it manually
    services.greetd = mkIf (cfg.windowManager == "mangowc") {
      enable = true;
      settings = {
        default_session = {
          command = let
            greeterScript = pkgs.writeShellScript "dms-greeter-mangowc" ''
              export PATH=$PATH:${lib.makeBinPath [quickshell pkgs.mangowc]}
              exec sh ${dmsShell}/share/quickshell/dms/Modules/Greetd/assets/dms-greeter \
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

    # Create MangoWC configuration file for greeter (mangowc only)
    environment.etc."greetd/mangowc.conf" = mkIf (cfg.windowManager == "mangowc") {
      text = ''
        # MangoWC greeter configuration
        # Managed by NixOS configuration
      '';
    };

    # Setup cache directory and config sync for mangowc greeter
    systemd.tmpfiles.settings."10-dmsgreeter-mangowc" = mkIf (cfg.windowManager == "mangowc") {
      "/var/lib/dms-greeter".d = {
        user = "greeter";
        group = "greeter";
        mode = "0750";
      };
    };

    systemd.services.greetd.preStart = mkIf (cfg.windowManager == "mangowc") (
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
  };
}
