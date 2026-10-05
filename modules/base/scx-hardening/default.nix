{
  config,
  lib,
  ...
}: {
  # No ProtectKernelTunables/RestrictRealtime: lavd may touch cpufreq sysfs, untested.
  systemd.services.scx.serviceConfig = lib.mkIf config.services.scx.enable {
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    PrivateTmp = true;
    ProtectHome = true;
    PrivateNetwork = true;
    PrivateDevices = true;
    ProtectClock = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    RestrictNamespaces = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    SystemCallArchitectures = "native";
    RestrictAddressFamilies = ["AF_UNIX"];
  };
}
