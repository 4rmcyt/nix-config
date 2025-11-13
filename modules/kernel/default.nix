{
  config,
  lib,
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
        default = /var/lib/modprobed-db/modprobed.db;
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
  ];
}
