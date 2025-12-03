{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.kernel.optimized;

  # Helper function to read and parse modprobed.db
  getModulesList = modulesPath:
    if builtins.pathExists modulesPath
    then filter (m: m != "") (splitString "\n" (builtins.readFile modulesPath))
    else [];

  # Helper function to count modules
  getModulesCount = modulesPath: length (getModulesList modulesPath);
in {
  imports = [
    ./modprobed-db.nix
  ];

  options.my.kernel = {
    optimized = {
      enable = mkEnableOption "kernel optimization tracking with modprobed-db";

      modulesPath = mkOption {
        type = types.path;
        default = /root/.config/modprobed.db;
        description = "Path to modprobed.db file containing kernel modules";
      };

      cpuArch = mkOption {
        type = types.str;
        default = "znver4";
        description = ''
          CPU architecture for Nix build features.
          Common values: znver4 (Ryzen 7000/9000), znver3 (Ryzen 5000), znver2 (Ryzen 3000), znver (Ryzen 1000/2000)
        '';
      };

      showInstructions = mkOption {
        type = types.bool;
        default = true;
        description = "Show module tracking information on build";
      };
    };
  };

  config = mkMerge [
    # Base modprobed-db service configuration
    {
      services.modprobed-db = {
        enable = true;
        user = "root";
        interval = "hourly";
      };
    }

    # Optimized kernel configuration (when enabled)
    (mkIf cfg.enable {
      # Display optimization info
      warnings = mkIf cfg.showInstructions [
        ''
          ╔════════════════════════════════════════════════════════════╗
          ║     Kernel Module Tracking with modprobed-db enabled      ║
          ╚════════════════════════════════════════════════════════════╝

          📊 Configuration:
          ├─ Module database: ${toString cfg.modulesPath}
          ├─ CPU architecture: ${cfg.cpuArch}
          ├─ Modules tracked: ${toString (getModulesCount cfg.modulesPath)}
          └─ Exported to: /etc/modprobed-modules.txt (after rebuild)

          🔍 Recently tracked modules (first 10):
          ${concatStringsSep ", " (take 10 (getModulesList cfg.modulesPath))}${
            optionalString ((getModulesCount cfg.modulesPath) > 10)
            "... and ${toString ((getModulesCount cfg.modulesPath) - 10)} more"
          }

          ℹ️  Automatic tracking runs hourly via systemd (modprobed-db.service)
        ''
      ];

      # System features for build - adds CPU-specific compilation flags
      nix.settings.system-features = mkIf (cfg.cpuArch != null) [
        "gccarch-${cfg.cpuArch}"
      ];

      # Export module list for external tools
      environment.etc."modprobed-modules.txt" = mkIf (builtins.pathExists cfg.modulesPath) {
        text = concatStringsSep "\n" (getModulesList cfg.modulesPath);
        mode = "0444";
      };
    })
  ];
}
