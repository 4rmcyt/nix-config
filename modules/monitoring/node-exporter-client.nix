{
  config,
  lib,
  ...
}: {
  options.my.nodeExporter = {
    enable = lib.mkEnableOption "Prometheus node_exporter client";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open port 9100 in the firewall.";
    };
    extraCollectors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional collectors to enable (e.g. zfs, thermal_zone).";
    };
  };

  config = lib.mkIf config.my.nodeExporter.enable {
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors =
        [
          "cpu"
          "diskstats"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "stat"
          "systemd"
          "time"
          "textfile"
        ]
        ++ config.my.nodeExporter.extraCollectors;
      extraFlags = ["--collector.textfile.directory=/var/lib/prometheus-node-exporter-text-files"];
    };

    # Write current NixOS generation number on every activation
    system.activationScripts.node-exporter-system-version = {
      supportsDryActivation = true;
      text = ''
        mkdir -pm 0775 /var/lib/prometheus-node-exporter-text-files
        (
          echo -n "system_version "
          readlink /nix/var/nix/profiles/system | cut -d- -f2
        ) > /var/lib/prometheus-node-exporter-text-files/system-version.prom.next
        mv /var/lib/prometheus-node-exporter-text-files/system-version.prom.next \
           /var/lib/prometheus-node-exporter-text-files/system-version.prom
      '';
    };

    networking.firewall.allowedTCPPorts = lib.mkIf config.my.nodeExporter.openFirewall [9100];
  };
}
