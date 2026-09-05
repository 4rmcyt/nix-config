{config, ...}: {
  sops.secrets.ntfy_alertmanager_config = {
    sopsFile = ../../secrets/ntfy.yaml;
  };

  services.prometheus.alertmanager = {
    enable = true;
    port = config.my.network.ports.alertmanager;
    listenAddress = "127.0.0.1";
    extraFlags = ["--cluster.listen-address="];
    configuration = {
      route = {
        receiver = "ntfy";
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "4h";
      };
      receivers = [
        {
          name = "ntfy";
          webhook_configs = [
            {
              url = "http://127.0.0.1:${toString config.my.network.ports.alertmanager-ntfy}/hook";
              send_resolved = true;
            }
          ];
        }
      ];
    };
  };

  services.prometheus.alertmanager-ntfy = {
    enable = true;
    extraConfigFiles = [config.sops.secrets.ntfy_alertmanager_config.path];
    settings = {
      http.addr = "127.0.0.1:${toString config.my.network.ports.alertmanager-ntfy}";
      ntfy = {
        baseurl = "http://127.0.0.1:9991";
        notification.topic = "alerts";
      };
    };
  };
}
