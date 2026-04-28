{config, ...}: {
  # =================================================================
  # SOPS Secrets for Redis
  # =================================================================
  sops.secrets = {
    redis-oauth2-proxy-password = {
      sopsFile = ../../../secrets/redis.yaml;
      key = "oauth2_proxy_password";
      owner = "redis";
      group = "redis";
      mode = "0440"; # Group-readable so authelia user can access
    };
  };

  # =================================================================
  # Users and Groups
  # =================================================================
  # Create redis user/group for secret ownership
  users.users.redis = {
    isSystemUser = true;
    group = "redis";
  };
  users.groups.redis = {};

  # NixOS Redis module creates dynamic user/group: redis-homeserver
  # Add authelia to redis-homeserver group for socket access
  users.groups.redis-homeserver = {
    members = ["authelia"]; # Services that need Redis socket access
  };

  # =================================================================
  # Centralized Redis Server
  # =================================================================
  services.redis.servers.homeserver = {
    enable = true;

    # Network configuration
    bind = "127.0.0.1 10.88.0.1";
    port = 6379;

    # Unix socket for better performance
    unixSocket = "/run/redis-homeserver/redis.sock";
    unixSocketPerm = 660;

    # Simple password authentication - oauth2-proxy password
    requirePassFile = config.sops.secrets.redis-oauth2-proxy-password.path;

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
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];

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
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
      ];
    };
  };
}
# =================================================================
# Configuration Notes
# =================================================================
# Simple Redis setup: one password, separate databases per service
#
# Database allocation:
# - oauth2-proxy: database 0
# - paperless: database 1 (when enabled)
# - authelia: database 2 (when enabled)
#
# All services use the same password (oauth2_proxy_password from secrets)
# Isolation is achieved through different database numbers
#
# Connection format:
# - TCP: redis://127.0.0.1:6379/0 + redis-password-file option

