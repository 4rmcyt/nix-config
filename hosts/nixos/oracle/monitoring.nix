{...}: {
  # Prometheus — scrapes headscale, node-exporter, crowdsec.
  # Bound to 127.0.0.1; homeserver Grafana reaches it via Tailscale after mesh is up.
  # Grafana is NOT running here — 1 GB RAM e2-micro can't afford it.
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
        job_name = "gcp-relay-node";
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
}
