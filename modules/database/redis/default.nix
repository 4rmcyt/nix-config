{
  config,
  pkgs,
  ...
}: let
  # Centralized Redis configuration for homeserver
  # Each service gets its own ACL user with access only to their database
  # ACL configuration file
  # Reference: https://redis.io/docs/management/security/acl/
  aclUsers = pkgs.writeText "redis-users.acl" ''
    # Default user - disabled for security
    user default off nopass ~* &* +@all

    # OAuth2 Proxy user - database 0
    # Permissions: all commands except dangerous ones, all keys, select db 0
    user oauth2-proxy on #${config.sops.secrets.redis-oauth2-proxy-password.path} ~* &* +@all -@dangerous resetchannels resetkeys

    # Add more service users here when needed:
    # Paperless user - database 1
    # user paperless on #${config.sops.secrets.redis-paperless-password.path} ~paperless:* &* +@all -@dangerous resetchannels resetkeys

    # Authentik user - database 2
    # user authentik on #${config.sops.secrets.redis-authentik-password.path} ~* &* +@all -@dangerous resetchannels resetkeys
  '';
in {
  # =================================================================
  # SOPS Secrets for Redis
  # =================================================================
  sops.secrets = {
    # Service-specific passwords
    redis-oauth2-proxy-password = {
      sopsFile = ../../../secrets/redis.yaml;
      key = "oauth2_proxy_password";
      owner = "redis";
      group = "redis";
      mode = "0400";
    };

    # Add more service passwords when needed:
    # redis-paperless-password = {
    #   sopsFile = ../../../secrets/redis.yaml;
    #   key = "paperless_password";
    #   owner = "redis";
    #   group = "redis";
    #   mode = "0400";
    # };

    # redis-authentik-password = {
    #   sopsFile = ../../../secrets/redis.yaml;
    #   key = "authentik_password";
    #   owner = "redis";
    #   group = "redis";
    #   mode = "0400";
    # };
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

    # Unix socket for better performance
    unixSocket = "/run/redis-homeserver/redis.sock";
    unixSocketPerm = 660;

    # Database configuration
    databases = 16; # Support databases 0-15

    # Resource limits
    maxmemory = "1GB";
    maxmemoryPolicy = "allkeys-lru";

    # Security and configuration settings
    settings = {
      # ACL configuration - load users from file
      aclfile = "${aclUsers}";

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

      # Rename dangerous commands for additional security
      "rename-command FLUSHDB" = ''"FLUSHDB_DISABLED"'';
      "rename-command FLUSHALL" = ''"FLUSHALL_DISABLED"'';
      "rename-command CONFIG" = ''"CONFIG_DISABLED"'';
      "rename-command SHUTDOWN" = ''"SHUTDOWN_DISABLED"'';
      "rename-command DEBUG" = ''"DEBUG_DISABLED"'';
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
# This Redis instance uses ACL-based authentication with separate users per service.
# Each service has its own username and password with isolated access.
#
# Database allocation:
# - oauth2-proxy: database 0 (user: oauth2-proxy)
# - paperless: database 1 (user: paperless) - when enabled
# - authentik: database 2 (user: authentik) - when enabled
#
# Connection format:
# unix:///run/redis-homeserver/redis.sock?username=<service>&password=<from-sops>
#
# To add a new service:
# 1. Add password secret in sops.secrets section above
# 2. Add ACL user definition in aclUsers
# 3. Add service to users.groups.redis.members
# 4. Add service group to users.users.redis.extraGroups
# 5. Configure service to use unix socket with username and password

