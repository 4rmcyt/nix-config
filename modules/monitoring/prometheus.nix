{config, ...}: {
  users.users.prometheus = {
    isSystemUser = true;
    description = "Prometheus daemon user";
    group = "prometheus";
  };
  users.groups.prometheus = {};

  networking.firewall.allowedTCPPorts = [
    config.my.network.ports.prometheus
    config.my.network.ports.node-exporter
    9199 # NUT Exporter
  ];

  services.prometheus = {
    enable = true;
    port = config.my.network.ports.prometheus;
    retentionTime = "30d";
    globalConfig.scrape_interval = "1m";
    ruleFiles = [./alerts/homeserver.yaml];
    alertmanagers = [
      {
        static_configs = [{targets = ["127.0.0.1:${toString config.my.network.ports.alertmanager}"];}];
      }
    ];

    exporters = {
      nut = {
        enable = true;
        nutServer = "localhost";
        nutUser = "upsmon";
        passwordPath = config.sops.secrets.nut_password.path;
        nutVariables = [
          "battery.charge"
          "battery.runtime"
          "battery.voltage"
          "battery.voltage.nominal"
          "input.voltage"
          "input.voltage.nominal"
          "ups.load"
          "ups.status"
        ];
      };
    };

    scrapeConfigs = [
      {
        job_name = "desktop-node";
        static_configs = [
          {
            targets = [
              "${config.my.network.hosts.desktop_lan}:${toString config.my.network.ports.node-exporter}"
            ];
          }
        ];
      }
      {
        job_name = "homeserver-node";
        static_configs = [{targets = ["localhost:${toString config.my.network.ports.node-exporter}"];}];
      }
      {
        job_name = "nut-exporter";
        static_configs = [{targets = ["localhost:9199"];}];
        metrics_path = "/ups_metrics";
      }
      {
        job_name = "prometheus";
        static_configs = [{targets = ["localhost:${toString config.my.network.ports.prometheus}"];}];
      }
      {
        job_name = "traefik";
        static_configs = [{targets = ["localhost:${toString config.my.network.ports.traefik-metrics}"];}];
      }
      {
        job_name = "crowdsec";
        static_configs = [{targets = ["localhost:6060"];}];
      }
      {
        job_name = "gcp-relay-node";
        static_configs = [{targets = ["${config.my.network.hosts."gcp-relay_ts"}:${toString config.my.network.ports.node-exporter}"];}];
      }
      {
        job_name = "matebook-node";
        static_configs = [{targets = ["${config.my.network.hosts.matebook_wifi}:${toString config.my.network.ports.node-exporter}"];}];
      }
    ];
  };
}
