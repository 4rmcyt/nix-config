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

  users.users.redis = {
    isSystemUser = true;
    group = "redis";
  };
  users.groups.redis = {};

  # NixOS's Redis module creates its own dynamic user/group: redis-homeserver.
  users.groups.redis-homeserver = {
    members = [];
  };

  services.redis.servers.homeserver = {
    enable = true;

    bind = "127.0.0.1";
    port = 6379;

    unixSocket = "/run/redis-homeserver/redis.sock";
    unixSocketPerm = 660;

    # No consumers left; kept idle. Secret name is from an earlier oauth2-proxy setup.
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

  systemd.services.redis-homeserver = {
    after = ["network.target"];
    serviceConfig =
      {
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      }
      // {
        Restart = "on-failure";
        RestartSec = "5s";
        MemoryMax = "1.2G";
        CPUQuota = "75%";

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
