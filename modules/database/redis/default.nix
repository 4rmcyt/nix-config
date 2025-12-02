{
  config,
  pkgs,
  ...
}: let
  # Centralized Redis configuration for homeserver
  # Each service gets its own database number and ACL user
  # Database allocation (for documentation and future use)
  # databases = {
  #   oauth2-proxy = 0;
  #   # Add more services here when needed:
  #   # paperless = 1;
  #   # authentik = 2;
  # };
  # ACL configuration file generation
  # Each service gets its own user with access only to their database
  aclConfig = pkgs.writeText "redis-users.acl" ''
    # Default user - disabled for security
    user default off nopass

    # OAuth2 Proxy user - database 0
    user oauth2-proxy on >${config.sops.secrets.redis-oauth2-proxy-password.path} ~* &* +@all -@dangerous

    # Add more service users here when needed:
    # Paperless user - database 1
    # user paperless on >${config.sops.secrets.redis-paperless-password.path} ~paperless:* &* +@all -@dangerous

    # Authentik user - database 2
    # user authentik on >${config.sops.secrets.redis-authentik-password.path} ~* &* +@all -@dangerous
  '';
in {
  # =================================================================
  # SOPS Secrets for Redis
  # =================================================================
  sops.secrets = {
    # Main Redis admin password
    redis-admin-password = {
      sopsFile = ../../../secrets/redis.yaml;
      key = "admin_password";
      owner = "redis";
      group = "redis";
      mode = "0400";
    };

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

    # Unix socket for better performance (used by oauth2-proxy)
    unixSocket = "/run/redis-homeserver/redis.sock";
    unixSocketPerm = 660;

    # Database configuration
    databases = 16; # Support databases 0-15

    # Authentication - use ACL file
    aclFile = "${aclConfig}";

    # Resource limits
    maxmemory = "1GB";
    maxmemoryPolicy = "allkeys-lru";

    # Security: Disable dangerous commands
    settings = {
      # Rename dangerous commands
      rename-command = {
        FLUSHDB = "";
        FLUSHALL = "";
        KEYS = "";
        CONFIG = "CONFIG_${builtins.substring 0 8 (builtins.hashString "sha256" "random")}";
        SHUTDOWN = "";
        DEBUG = "";
      };

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
