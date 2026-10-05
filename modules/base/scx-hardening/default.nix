{
  config,
  lib,
  ...
}: {
  # mkIf on the whole block: declaring systemd.services.scx at all generates an empty unit.
  config = lib.mkIf config.services.scx.enable {
    # No ProtectKernelTunables/RestrictRealtime: lavd may touch cpufreq sysfs, untested.
    systemd.services.scx.serviceConfig = {
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
  };
}
