{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.kernel;
in {
  imports = [
    ./modprobed-db.nix
  ];

  options.my.kernel = {
    optimized = {
      enable = mkEnableOption "kernel optimization using modprobed-db";

      modulesPath = mkOption {
        type = types.path;
        default = /var/lib/modprobed-db/.config/modprobed-db/modprobed.db;
        description = "Path to modprobed.db file containing kernel modules";
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

    # Kernel optimization configuration
    (mkIf cfg.optimized.enable {
      # Inform user about kernel optimization
      # The modprobed.db file will be used during manual kernel compilation
      warnings = [
        ''
          Kernel optimization is enabled. To use modprobed-db data:

          1. Ensure you've collected module data: modprobed-db list
          2. The module database is at: ${toString cfg.optimized.modulesPath}
          3. For custom kernel builds, use the CachyOS kernel configurator
             or manually configure your kernel with the tracked modules.

          The modprobed-db systemd service is running hourly to track modules.
        ''
      ] ++ optional (!builtins.pathExists cfg.optimized.modulesPath) ''
        Warning: modprobed.db not found at ${toString cfg.optimized.modulesPath}.
        Run the system for a few days/weeks to collect module data.
      '';
    })
  ];
}
