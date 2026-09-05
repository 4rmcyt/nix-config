{config, ...}: {
  sops.secrets = {
    redis-oauth2-proxy-password = {
      sopsFile = ../../../secrets/redis.yaml;
      key = "oauth2_proxy_password";
      owner = "redis";
      group = "redis";
      mode = "0440";
    };
  };

  # Create redis user/group for secret ownership
  users.users.redis = {
    isSystemUser = true;
    group = "redis";
  };
  users.groups.redis = {};

  # NixOS Redis module creates dynamic user/group: redis-homeserver
  # Add services to redis-homeserver group for socket access
  users.groups.redis-homeserver = {
    members = []; # Services that need Redis socket access
  };

  services.redis.servers.homeserver = {
    enable = true;

    bind = "127.0.0.1 10.88.0.1";
    port = 6379;

    # Unix socket for better performance
    unixSocket = "/run/redis-homeserver/redis.sock";
    unixSocketPerm = 660;

    # Secret is still named redis-oauth2-proxy-password from an earlier
    # setup; the only current consumer is dispatcharr (database 3).
    requirePassFile = config.sops.secrets.redis-oauth2-proxy-password.path;

    databases = 16;

    settings = {
      maxmemory = "1GB";
      maxmemory-policy = "allkeys-lru";

      loglevel = "notice";
      syslog-enabled = true;

      save = [
        "900 1"
        "300 10"
        "60 10000"
      ];

      appendonly = "yes";
      appendfsync = "everysec";

      tcp-keepalive = "300";
      timeout = "0";
    };
  };

  networking.firewall.allowedTCPPorts = [
    # 6379 # Commented out - only allow local connections
  ];

  systemd.services.redis-homeserver = {
    after = ["network.target"];
    serviceConfig =
      config.my.hardening.serviceBase
      // {
        Restart = "on-failure";
        RestartSec = "5s";
        MemoryMax = "1.2G";
        CPUQuota = "75%";

        # Allow Redis to write to its data directory
        ReadWritePaths = [
          "/var/lib/redis-homeserver"
          "/run/redis-homeserver"
        ];

        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];

        CapabilityBoundingSet = "";
        AmbientCapabilities = "";

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
