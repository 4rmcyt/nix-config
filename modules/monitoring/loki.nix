{
  config,
  lib,
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    config.my.network.ports.loki
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/loki/rules 0755 loki loki -"
    "d /var/lib/loki/rules/fake 0755 loki loki -"
    "d /var/lib/loki/rules-temp 0755 loki loki -"
    "L+ /var/lib/loki/rules/fake/homeserver.yaml - - - - ${./alerts/loki-rules.yaml}"
  ];

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server.http_listen_port = config.my.network.ports.loki;
      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore.store = "inmemory";
            replication_factor = 1;
          };
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 1048576;
        chunk_retain_period = "30s";
      };
      schema_config.configs = [
        {
          from = "2025-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-index";
          cache_location = "/var/lib/loki/tsdb-cache";
        };
        filesystem.directory = "/var/lib/loki/chunks";
      };
      compactor = {
        working_directory = "/var/lib/loki/compactor";
        compaction_interval = "10m";
        retention_enabled = true;
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
        delete_request_store = "filesystem";
        compactor_ring.kvstore.store = "inmemory";
      };
      limits_config = {
        retention_period = "30d";
        reject_old_samples = true;
        reject_old_samples_max_age = "30d";
        ingestion_rate_mb = 16;
        ingestion_burst_size_mb = 32;
        allow_structured_metadata = false;
      };
      query_range.cache_results = true;
      frontend.scheduler_address = "";
      frontend_worker.scheduler_address = "";
      ruler = {
        storage = {
          type = "local";
          local.directory = "/var/lib/loki/rules";
        };
        rule_path = "/var/lib/loki/rules-temp";
        alertmanager_url = "http://127.0.0.1:${toString config.my.network.ports.alertmanager}";
        enable_alertmanager_v2 = true;
        enable_api = true;
        ring.kvstore.store = "inmemory";
      };
    };
  };

  # PrivateNetwork/IPAddressDeny deliberately not set: Loki has to accept push traffic
  # from Alloy over the LAN.
  systemd.services.loki.serviceConfig = {
    ProtectSystem = "full";
    ProtectHome = true;
    # nixpkgs' loki.nix hardcodes PrivateTmp = true (plain, not mkDefault) — needs mkForce.
    PrivateTmp = lib.mkForce "disconnected";
    PrivateDevices = true;
    PrivateMounts = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    LockPersonality = true;
    RestrictRealtime = true;
    ProtectClock = true;
    MemoryDenyWriteExecute = true;
    RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_NETLINK" "AF_UNIX"];
    SocketBindDeny = ["ipv4:udp" "ipv6:udp"];
    CapabilityBoundingSet = "~CAP_BLOCK_SUSPEND CAP_BPF CAP_CHOWN CAP_IPC_LOCK CAP_KILL CAP_MKNOD CAP_NET_RAW CAP_PERFMON CAP_SYS_BOOT CAP_SYS_CHROOT CAP_SYS_MODULE CAP_SYS_NICE CAP_SYS_PACCT CAP_SYS_PTRACE CAP_SYS_TIME CAP_SYS_TTY_CONFIG CAP_SYSLOG CAP_WAKE_ALARM";
    # A Nix list of "~@group:EPERM" strings renders as one SystemCallFilter= line
    # per element, but systemd only honors the leading "~" on the first — use a
    # single "~"-prefixed string with SystemCallErrorNumber set separately instead.
    SystemCallErrorNumber = "EPERM";
    SystemCallFilter = "~@aio @chown @clock @cpu-emulation @debug @ipc @keyring @memlock @module @mount @obsolete @pkey @privileged @raw-io @reboot @resources @sandbox @setuid @swap";
  };
}
