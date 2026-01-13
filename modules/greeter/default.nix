{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.my.desktop;
in {
  config = mkIf (cfg.displayManager == "greetd" && cfg.windowManager == "mangowc") {
    # Manual greetd configuration for mangowc using dms-greeter
    # Note: This requires the dms.nixosModules.dankMaterialShell to be imported
    # which provides the dms package with the greeter script
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = let
            # Get DMS and quickshell packages from inputs
            system = pkgs.stdenv.hostPlatform.system;
            dmsShell = inputs.dms.packages.${system}.default;
            quickshell = inputs.quickshell.packages.${system}.default or inputs.dms.packages.${system}.default.passthru.quickshell or pkgs.quickshell;
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

    # Create MangoWC configuration file for greeter
    environment.etc."greetd/mangowc.conf".text = ''
      # MangoWC greeter configuration
      # Managed by NixOS configuration
    '';

    # Setup cache directory and config sync for mangowc greeter
    systemd.tmpfiles.settings."10-dmsgreeter-mangowc" = {
      "/var/lib/dms-greeter".d = {
        user = "greeter";
        group = "greeter";
        mode = "0750";
      };
    };

    systemd.services.greetd.preStart = let
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
    '';
  };
}
