{
  config,
  pkgs,
  ...
}: {
  # =================================================================
  # SOPS Secrets for Redis
  # =================================================================
  sops.secrets = {
    redis-oauth2-proxy-password = {
      sopsFile = ../../../secrets/redis.yaml;
      key = "oauth2_proxy_password";
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

    # Database configuration
    databases = 16; # Support databases 0-15

    # Security and configuration settings
    settings = {
      # Disable default user for security
      # ACL will be configured via post-start script

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

  # =================================================================
  # ACL Configuration via Post-Start Script
  # =================================================================
  systemd.services.redis-acl-setup = {
    description = "Configure Redis ACL users with SOPS passwords";
    after = ["redis-homeserver.service"];
    requires = ["redis-homeserver.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "redis";
      Group = "redis";
    };

    script = ''
      # Wait for Redis to be ready
      for i in {1..30}; do
        if ${pkgs.redis}/bin/redis-cli -s ${config.services.redis.servers.homeserver.unixSocket} ping 2>/dev/null | grep -q PONG; then
          break
        fi
        sleep 1
      done

      # Read password from SOPS secret
      OAUTH2_PASSWORD=$(cat ${config.sops.secrets.redis-oauth2-proxy-password.path})

      # Configure ACL users
      ${pkgs.redis}/bin/redis-cli -s ${config.services.redis.servers.homeserver.unixSocket} <<EOF
      ACL SETUSER default off
      ACL SETUSER oauth2-proxy on >"$OAUTH2_PASSWORD" ~* &* +@all -@dangerous resetchannels resetkeys
      ACL SAVE
      EOF
    '';
  };
}
# =================================================================
# Configuration Notes
# =================================================================
# This Redis instance uses ACL-based authentication with separate users per service.
# Each service has its own username and password with isolated access.
#
# ACL is configured at runtime via systemd service because passwords are in SOPS secrets.
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
# 2. Add ACL SETUSER command in redis-acl-setup script
# 3. Add service to users.groups.redis.members
# 4. Add service group to users.users.redis.extraGroups
# 5. Configure service to use unix socket with username and password
