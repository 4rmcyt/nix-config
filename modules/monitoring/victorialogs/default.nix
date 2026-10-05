{config, ...}: let
  inherit (config.my.network) ports;
  url = "http://127.0.0.1:${toString ports.victorialogs}";
in {
  services.victorialogs = {
    enable = true;
    listenAddress = ":${toString ports.victorialogs}";
    extraOptions = [
      "-retentionPeriod=30d"
      # Stores the sender IP as remote_ip, so CrowdSec only trusts Caddy lines that really came from gcp-relay.
      "-journald.useRemoteIP=true"
    ];
  };

  # zdata/victorialogs (disko) must be mounted before the DynamicUser StateDirectory is used.
  systemd.services.victorialogs.unitConfig.RequiresMountsFor = ["/var/lib/private/victorialogs"];

  # homeserver ships its own journal the same way as every other host.
  my.journalUpload = {
    enable = true;
    url = "${url}/insert/journald";
  };

  services.vmalert.instances.logs = {
    enable = true;
    settings = {
      "datasource.url" = url;
      "notifier.url" = ["http://127.0.0.1:${toString ports.alertmanager}"];
      "rule.defaultRuleType" = "vlogs";
      httpListenAddr = "127.0.0.1:${toString ports.vmalert}";
    };
    rules = import ./rules.nix;
  };

  systemd.services.vmalert-logs = {
    after = ["victorialogs.service"];
    wants = ["victorialogs.service"];
  };
}
