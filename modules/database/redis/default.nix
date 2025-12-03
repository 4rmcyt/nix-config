{config, ...}: {
  # =================================================================
  # SOPS Secrets for Redis
  # =================================================================
  sops.secrets = {
    # Redis password for authentication
    redis-password = {
      sopsFile = ../../../secrets/redis.yaml;
      key = "redis_password";
      owner = "redis";
      group = "redis";
      mode = "0400";
    };
  };

  # =================================================================
  # Users and Groups
  # =================================================================
  users.users.redis = {
    isSystemUser = true;
    group = "redis";
    extraGroups = ["oauth2-proxy"]; # Add service groups that need access
  };
  users.groups.redis = {
    members = ["oauth2-proxy"]; # Services that need Redis access
  };

  # =================================================================
  # Centralized Redis Server
  # =================================================================
  services.redis.servers.homeserver = {
    enable = true;

    # Network configuration
    bind = "127.0.0.1 ::1"; # Local only
    port = 6379;

    # Unix socket for better performance (used by oauth2-proxy)
    unixSocket = "/run/redis-homeserver/redis.sock";
    unixSocketPerm = 660;

    # Database configuration
    databases = 16; # Support databases 0-15

    # Password authentication
    requirePass = config.sops.secrets.redis-password.path;

    # Resource limits
    maxmemory = "1GB";
    maxmemoryPolicy = "allkeys-lru";

    # Security: Disable dangerous commands
    settings = {
      # Logging
      loglevel = "notice";
      syslog-enabled = "yes";

      # Persistence settings
      save = "900 1 300 10 60 10000";

      # Append-only file for durability
      appendonly = "yes";
      appendfsync = "everysec";

      # Performance tuning
      tcp-keepalive = "300";
      timeout = "0";

      # Rename dangerous commands for security
      "rename-command FLUSHDB" = ''"FLUSHDB_DISABLED"'';
      "rename-command FLUSHALL" = ''"FLUSHALL_DISABLED"'';
      "rename-command CONFIG" = ''"CONFIG_DISABLED"'';
      "rename-command SHUTDOWN" = ''"SHUTDOWN_DISABLED"'';
      "rename-command DEBUG" = ''"DEBUG_DISABLED"'';
      "rename-command KEYS" = ''"KEYS_DISABLED"'';
    };
  };

  # =================================================================
  # Firewall Configuration
  # =================================================================
  networking.firewall.allowedTCPPorts = [
    # 6379 # Commented out - only allow local connections
  ];

  # =================================================================
  # Systemd Service Hardening
  # =================================================================
  systemd.services.redis-homeserver = {
    serviceConfig = {
      # Resource limits
      MemoryMax = "1.2G";
      CPUQuota = "75%";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";

      # Allow Redis to write to its data directory
      ReadWritePaths = [
        "/var/lib/redis-homeserver"
        "/run/redis-homeserver"
      ];

      # Network restrictions
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];

      # Capabilities
      CapabilityBoundingSet = "";
      AmbientCapabilities = "";

      # Additional hardening
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      SystemCallFilter = ["@system-service" "~@privileged"];
    };
  };
}

# =================================================================
# Configuration Notes
# =================================================================
# This Redis instance uses simple password authentication via unix socket.
# OAuth2-proxy connects using: unix:///run/redis-homeserver/redis.sock?password=...
#
# To add more services:
# 1. Add service group to users.groups.redis.members
# 2. Add service to users.users.redis.extraGroups
# 3. Configure service to use unix socket with password from redis_password
#
# Database allocation (by convention):
# - oauth2-proxy: database 0
# - paperless: database 1 (when enabled)
# - authentik: database 2 (when enabled)
