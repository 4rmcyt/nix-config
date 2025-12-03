{config, ...}: {
  # =================================================================
  # SOPS Secrets for Redis
  # =================================================================
  sops.secrets = {
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
    bind = "127.0.0.1"; # Local only (IPv4)
    port = 6379;

    # Unix socket for better performance
    unixSocket = "/run/redis-homeserver/redis.sock";
    unixSocketPerm = 660;

    # Password authentication
    requirePassFile = config.sops.secrets.redis-password.path;

    # Database configuration
    databases = 16; # Support databases 0-15

    # Security and configuration settings
    settings = {
      # Resource limits
      maxmemory = "1GB";
      maxmemory-policy = "allkeys-lru";

      # Logging
      loglevel = "notice";
      syslog-enabled = true;

      # Persistence settings
      save = [
        "900 1"
        "300 10"
        "60 10000"
      ];

      # Append-only file for durability
      appendonly = "yes";
      appendfsync = "everysec";

      # Performance tuning
      tcp-keepalive = "300";
      timeout = "0";
    };
  };

  # =================================================================
  # Firewall Configuration
  # =================================================================
  networking.firewall.allowedTCPPorts = [
    # 6379 # Commented out - only allow local connections
  ];

  # =================================================================
  # Systemd Service Configuration
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
# This Redis instance uses simple password authentication with database separation.
# Each service connects with the same password but uses a different database number.
#
# Database allocation:
# - oauth2-proxy: database 0
# - paperless: database 1 (when enabled)
# - authentik: database 2 (when enabled)
#
# Connection format examples:
# - TCP: redis://:password@127.0.0.1:6379/0
# - TCP with password file: redis://127.0.0.1:6379/0 + redis-password-file option
# - Unix socket: unix:///run/redis-homeserver/redis.sock?db=0 + password-file option
#
# Database isolation provides separation without ACL complexity.
# Services use the same password but different database numbers for isolation.

