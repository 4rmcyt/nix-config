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
    textfileWriters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Local usernames granted write access (via a shared group) to the
        textfile-collector directory, so non-root services/timers can drop
        their own *.prom files without needing the exporter's DynamicUser.
        Group-based rather than POSIX ACL because the root filesystem here
        is ZFS mounted `noacl` — setfacl fails outright (ACLs unsupported at
        the mount level, not just acltype=off on the dataset).
      '';
    };
  };

  config = lib.mkIf config.my.nodeExporter.enable {
    users.groups.node-exporter-textfile = {};
    users.users = lib.genAttrs config.my.nodeExporter.textfileWriters (_: {
      extraGroups = ["node-exporter-textfile"];
    });

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

    # The exporter's DynamicUser owns the textfile dir (root:root won't stick,
    # it ends up nobody:nogroup 0775) — grant configured local users write
    # access via a shared group (setgid so new files inherit it) so their own
    # timers can drop *.prom files without root.
    system.activationScripts.node-exporter-textfile-acl = lib.mkIf (config.my.nodeExporter.textfileWriters != []) {
      supportsDryActivation = true;
      deps = ["node-exporter-system-version"];
      text = ''
        chgrp node-exporter-textfile /var/lib/prometheus-node-exporter-text-files
        chmod 2775 /var/lib/prometheus-node-exporter-text-files
      '';
    };

    networking.firewall.allowedTCPPorts = lib.mkIf config.my.nodeExporter.openFirewall [9100];
  };
}
