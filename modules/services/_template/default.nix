# Template for secure service configuration
{ config, ... }:
let
  serviceName = "example";
  serviceUser = serviceName;
  serviceGroup = serviceName;
  dataDir = "/var/lib/${serviceName}";
in
{
  # SOPS secrets
  sops.secrets."${serviceName}-password" = {
    sopsFile = ../../../secrets/services.yaml;
    owner = serviceUser;
    group = serviceGroup;
    mode = "0400";
  };

  # User and group creation
  users.groups.${serviceGroup} = { };
  users.users.${serviceUser} = {
    isSystemUser = true;
    group = serviceGroup;
    home = dataDir;
    createHome = true;
  };

  # Service configuration
  services.${serviceName} = {
    enable = true;

    # Security: bind to localhost only
    host = "127.0.0.1";
    port = 8080;

    # Use secrets
    passwordFile = config.sops.secrets."${serviceName}-password".path;

    # Data directory
    inherit dataDir;
    user = serviceUser;
    group = serviceGroup;
  };

  # Systemd security hardening
  systemd.services.${serviceName} = {
    serviceConfig = {
      # Resource limits
      MemoryMax = "512M";
      CPUQuota = "50%";
      TasksMax = 100;

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ dataDir ];

      # Network restrictions
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];

      # Capabilities
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];

      # File system restrictions
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;

      # System call filtering
      SystemCallFilter = [
        "@system-service"
        "~@privileged @resources"
      ];
      SystemCallErrorNumber = "EPERM";
    };
  };

  # Directory permissions
  systemd.tmpfiles.rules = [
    "d ${dataDir} 750 ${serviceUser} ${serviceGroup} - -"
    "d ${dataDir}/config 750 ${serviceUser} ${serviceGroup} - -"
    "d ${dataDir}/logs 750 ${serviceUser} ${serviceGroup} - -"
  ];

  # Backup inclusion
  services.borgmatic.settings.source_directories = [
    dataDir
  ];
}
