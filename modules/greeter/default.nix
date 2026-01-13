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
  quickshell = inputs.dms.packages.${pkgs.system}.quickshell;
in {
  config = mkIf (cfg.displayManager == "greetd") {
    # DankMaterialShell Greeter configuration for niri, hyprland, sway
    programs.dank-material-shell.greeter = mkIf (elem cfg.windowManager ["niri" "hyprland" "sway"]) {
      enable = mkDefault true;
      compositor.name = mkDefault cfg.windowManager;
      configHome = mkDefault "/home/${config.my.defaults.user}";
    };

    # Manual greetd configuration for mangowc with dms-greeter
    services.greetd = mkIf (cfg.windowManager == "mangowc") {
      enable = true;
      settings = {
        default_session = {
          command = let
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
