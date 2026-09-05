{config, ...}: {
  networking.firewall.allowedTCPPorts = [
    3100 # Loki
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
      server.http_listen_port = 3100;
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
}
