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
  # For niri and hyprland: Configure programs.dank-material-shell.greeter directly
  # in your host configuration or via the greeter module, since those are natively supported.
  # This module only handles mangowc which isn't in the greeter module's enum.

  config = mkIf (cfg.displayManager == "greetd" && cfg.windowManager == "mangowc") {
    # Manual greetd configuration for mangowc using dms-greeter
    # MangoWC is not in the greeter module's enum, so we configure it manually
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = let
            greeterScript = pkgs.writeShellScript "dms-greeter-mangowc" ''
              export PATH=${lib.makeBinPath [quickshell pkgs.mangowc]}:$PATH
              exec sh ${dmsShell}/share/quickshell/dms/Modules/Greetd/assets/dms-greeter --cache-dir /var/lib/dms-greeter --command mangowc -p ${dmsShell}/share/quickshell/dms -C /etc/greetd/mangowc.conf > /tmp/dms-greeter.log 2>&1
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
