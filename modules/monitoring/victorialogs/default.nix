{config, ...}: let
  inherit (config.my.network) ports;
  url = "http://127.0.0.1:${toString ports.victorialogs}";
in {
  # Loopback only: reads (Grafana, CrowdSec, vmalert) are local; remote hosts write via the Caddy ingest front below.
  services.victorialogs = {
    enable = true;
    listenAddress = "127.0.0.1:${toString ports.victorialogs}";
    extraOptions = [
      "-retentionPeriod=30d"
      # remote_ip comes from X-Forwarded-For, which only Caddy sets (clients' own XFF is dropped) — CrowdSec pins gcp-relay on it.
      "-journald.useRemoteIP=true"
    ];
  };

  # Write-only front: POST /insert/journald/* is proxied, everything else (LogsQL reads) is 403.
  services.caddy.virtualHosts."http://:${toString ports.victorialogs-ingest}" = {
    # No access log: each ingest request would itself be shipped back into VictoriaLogs.
    logFormat = null;
    extraConfig = ''
      @ingest {
        method POST
        path /insert/journald/*
      }
      handle @ingest {
        reverse_proxy ${url}
      }
      respond 403
    '';
  };

  # zdata/victorialogs (disko) must be mounted before the DynamicUser StateDirectory is used.
  systemd.services.victorialogs.unitConfig.RequiresMountsFor = ["/var/lib/private/victorialogs"];

  # homeserver ships its own journal the same way as every other host.
  my.journalUpload = {
    enable = true;
    url = "${url}/insert/journald";
  };

  # Tie the local uploader to VictoriaLogs: a VL restart mid-activation otherwise leaves it failed (exit 4, nh skips the profile).
  systemd.services.systemd-journal-upload = {
    after = ["victorialogs.service"];
    partOf = ["victorialogs.service"];
    wantedBy = ["victorialogs.service"];
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
