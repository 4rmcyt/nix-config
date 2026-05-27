{config, ...}: {
  sops.secrets.grafana_admin_password_oracle = {
    sopsFile = ../../../secrets/oracle.yaml;
    owner = config.users.users.grafana.name;
    mode = "0400";
  };

  sops.secrets.grafana_secret_key_oracle = {
    sopsFile = ../../../secrets/oracle.yaml;
    owner = config.users.users.grafana.name;
    mode = "0400";
  };

  # =================================================================
  # Prometheus — scrapes headscale, node-exporter, crowdsec
  # Never exposed publicly; homeserver Grafana reaches it via Tailscale
  # =================================================================
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "30d";

    globalConfig.scrape_interval = "1m";

    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9100;
      enabledCollectors = [
        "cpu"
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
        "stat"
        "time"
      ];
    };

    scrapeConfigs = [
      {
        job_name = "oracle-node";
        static_configs = [{targets = ["127.0.0.1:9100"];}];
      }
      {
        job_name = "headscale";
        static_configs = [{targets = ["127.0.0.1:9091"];}];
      }
      {
        job_name = "crowdsec";
        static_configs = [{targets = ["127.0.0.1:6060"];}];
      }
      {
        job_name = "prometheus";
        static_configs = [{targets = ["127.0.0.1:9090"];}];
      }
    ];
  };

  # =================================================================
  # Grafana — local access only, reachable via Tailscale
  # Homeserver Grafana does NOT scrape this; this is a local instance
  # for oracle-relay-specific dashboards.
  # =================================================================
  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3001;
        root_url = "http://localhost:3001";
      };
      security = {
        admin_password_file = config.sops.secrets.grafana_admin_password_oracle.path;
        secret_key = "$__file{${config.sops.secrets.grafana_secret_key_oracle.path}}";
      };
      analytics.reporting_enabled = false;
    };

    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:9090";
        isDefault = true;
      }
    ];
  };
}
