{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.my.network) podmanBridge podmanGateway;
  podmanPrefix = lib.elemAt (lib.splitString "/" config.my.network.subnets.podman) 1;
in {
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

    bind = "127.0.0.1 ${podmanGateway}";
    port = 6379;

    unixSocket = "/run/redis-homeserver/redis.sock";
    unixSocketPerm = 660;

    # Secret is still named redis-oauth2-proxy-password from an earlier setup; the
    # only current consumer is dispatcharr (database 3).
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
  ];

  # netavark otherwise only creates podman0 when the first container starts, long
  # after redis-homeserver needs to bind it.
  systemd.services.podman-bridge = {
    description = "Pre-create ${podmanBridge} bridge for host services binding the podman gateway";
    wantedBy = ["multi-user.target"];
    before = ["redis-homeserver.service" "postgresql.service" "podman.service"];
    after = ["network-pre.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "podman-bridge-up" ''
        set -eu
        ${pkgs.iproute2}/bin/ip link show ${podmanBridge} >/dev/null 2>&1 \
          || ${pkgs.iproute2}/bin/ip link add name ${podmanBridge} type bridge
        ${pkgs.iproute2}/bin/ip addr replace ${podmanGateway}/${podmanPrefix} dev ${podmanBridge}
        ${pkgs.iproute2}/bin/ip link set ${podmanBridge} up
      '';
    };
  };

  systemd.services.redis-homeserver = {
    after = ["network.target" "podman-bridge.service"];
    requires = ["podman-bridge.service"];
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
