{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.modprobed-db;
in {
  options.services.modprobed-db = {
    enable = mkEnableOption "modprobed-db automatic module tracking";

    user = mkOption {
      type = types.str;
      default = "root";
      description = "User to run modprobed-db as";
    };

    interval = mkOption {
      type = types.str;
      default = "hourly";
      description = "How often to run modprobed-db (systemd timer format)";
    };

    storeDir = mkOption {
      type = types.path;
      default = "/var/lib/modprobed-db";
      description = "Directory to store modprobed-db database";
    };
  };

  config = mkIf cfg.enable {
    # Ensure modprobed-db package is installed
    environment.systemPackages = [pkgs.modprobed-db];

    # Create storage directory
    systemd.tmpfiles.rules = [
      "d ${cfg.storeDir} 0755 ${cfg.user} root -"
    ];

    # Systemd service
    systemd.services.modprobed-db = {
      description = "Store currently loaded kernel modules";
      path = with pkgs; [coreutils gawk glibc.bin glibc.getent];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = "${pkgs.modprobed-db}/bin/modprobed-db store";
        WorkingDirectory = cfg.storeDir;
        Environment = "HOME=${cfg.storeDir}";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    # Systemd timer
    systemd.timers.modprobed-db = {
      description = "Timer for modprobed-db module tracking";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "1h";
        Persistent = true;
      };
    };
  };
}
