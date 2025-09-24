{ config, ... }:
{
  sops.secrets = {
    redis_password = {
      sopsFile = ../../../secrets/redis.yaml;
      key = "redis_password";
      owner = config.users.users.redis.name;
      group = config.users.groups.redis.name;
      mode = "0400";
    };
  };
  users.users.redis = {
    isSystemUser = true;
    group = "redis";
    extraGroups = [ "users" ];
  };
  users.groups.redis = { };

  networking.firewall.allowedTCPPorts = [
    6379 # Redis
  ];

  services.redis = {
    servers.redis = {
      enable = true;
      requirePass = config.sops.secrets.redis_password.path;
    };
  };
}
# services.redis.servers.default = {
#   enable = true;
#   # Security settings
#   bind = "127.0.0.1";  # Only local connections
#   port = 6379;
#   # Authentication
#   requirePass = "$(cat ${config.sops.secrets.redis-password.path})";
#   # Resource limits
#   maxmemory = "512MB";
#   maxmemoryPolicy = "allkeys-lru";
#   # Disable dangerous commands
#   rename-command = {
#     FLUSHDB = "";
#     FLUSHALL = "";
#     KEYS = "";
#     PEXPIRE = "";
#     DEL = "";
#     CONFIG = "";
#     SHUTDOWN = "";
#     DEBUG = "";
#     EVAL = "";
#   };
#   # Logging
#   logLevel = "warning";
#   syslogEnabled = true;
#   # Persistence settings
#   save = [
#     "900 1"   # Save after 900s if at least 1 key changed
#     "300 10"  # Save after 300s if at least 10 keys changed
#     "60 10000" # Save after 60s if at least 10000 keys changed
#   ];
#   # Append-only file
#   appendOnly = true;
#   appendFsync = "everysec";
# };
# # Add SOPS secret for Redis
# sops.secrets.redis-password = {
#   sopsFile = ../../../secrets/services.yaml;
#   owner = "redis";
#   group = "redis";
#   mode = "0400";
# };
# # Systemd security hardening
# systemd.services.redis-default.serviceConfig = {
#   # Resource limits
#   MemoryMax = "600M";
#   CPUQuota = "50%";
#   # Security hardening
#   NoNewPrivileges = true;
#   PrivateTmp = true;
#   ProtectHome = true;
#   ProtectSystem = "strict";
#   ReadWritePaths = [ "/var/lib/redis-default" ];
#   # Network restrictions
#   RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
#   # Capabilities
#   CapabilityBoundingSet = "";
#   AmbientCapabilities = "";
# };
