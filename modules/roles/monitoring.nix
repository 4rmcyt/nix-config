{
  config,
  lib,
  ...
}: {
  options.roles.monitoring = {
    enable = lib.mkEnableOption "monitoring role for observability stack";
  };

  config = lib.mkIf config.roles.monitoring.enable {
    # Ensure server role is enabled
    roles.server.enable = lib.mkDefault true;

    # Monitoring groups
    users.groups = {
      prometheus = {};
      grafana = {};
    };

    # Common monitoring directories
    systemd.tmpfiles.rules = [
      "d /var/lib/prometheus 755 prometheus prometheus -"
      "d /var/lib/grafana 755 grafana grafana -"
    ];

    # Firewall rules for monitoring
    networking.firewall.allowedTCPPorts = [
      config.my.network.ports.prometheus
      config.my.network.ports.grafana
      config.my.network.ports.node-exporter
    ];
  };
}
