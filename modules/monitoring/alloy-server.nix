{
  config,
  lib,
  ...
}: {
  services.alloy.enable = true;

  environment.etc."alloy/config.alloy".text = ''
    // ── Loki sink ────────────────────────────────────────────────
    loki.write "default" {
      endpoint {
        url = "http://localhost:${toString config.my.network.ports.loki}/loki/api/v1/push"
      }
    }

    // ── Traefik access log ────────────────────────────────────────
    local.file_match "traefik" {
      path_targets = [{
        __path__ = "/var/log/traefik/access.log",
        job       = "traefik",
        host      = "homeserver",
      }]
    }

    loki.source.file "traefik" {
      targets    = local.file_match.traefik.targets
      forward_to = [loki.write.default.receiver]
    }

    // ── Systemd journal ───────────────────────────────────────────
    // relabel rules stored here, applied via relabel_rules= in source.journal
    loki.relabel "journal" {
      forward_to = []
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      // __journal_priority_keyword: emerg, alert, crit, error, warning, notice, info, debug
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "emerg|alert|crit"
        target_label  = "level"
        replacement   = "critical"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "error"
        target_label  = "level"
        replacement   = "error"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "warning"
        target_label  = "level"
        replacement   = "warning"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "notice"
        target_label  = "level"
        replacement   = "notice"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "info"
        target_label  = "level"
        replacement   = "info"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "debug"
        target_label  = "level"
        replacement   = "debug"
      }
    }

    loki.source.journal "journal" {
      max_age       = "12h"
      relabel_rules = loki.relabel.journal.rules
      forward_to    = [loki.process.fix_container_level.receiver]
      labels        = {
        job  = "systemd-journal",
        host = "homeserver",
      }
    }

    // Containers (Python/celery) write INFO/DEBUG/WARNING to stderr → journald
    // marks them priority=error. Fix: for logs labelled error, check if the
    // line text starts with a Python log level and downgrade accordingly.
    loki.process "fix_container_level" {
      forward_to = [loki.write.default.receiver]

      stage.match {
        selector = "{level=\"error\"}"
        stage.regex {
          expression = "^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}[,.]\\d+ (?P<text_level>DEBUG|INFO|WARNING)"
        }
        stage.template {
          source   = "text_level"
          template = "{{ ToLower .Value }}"
        }
        stage.labels {
          values = { level = "text_level" }
        }
      }
    }
  '';

  systemd.services.alloy = {
    # Alloy tolerates a missing/stale mmdb file at startup, so not ordered after
    # geoip-update.service (its fetch can be a multi-minute catch-up run).
    serviceConfig = {
      SupplementaryGroups = ["systemd-journal"];

      # mkForce, not mkDefault: this is a list-typed option and nixpkgs' own definition
      # wins the priority filter before any list-merge happens (confirmed via `systemctl
      # show` — mkDefault made no difference on this exact module).
      CapabilityBoundingSet = lib.mkForce "";
      RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX"];
      SystemCallArchitectures = lib.mkDefault "native";
      # SystemCallFilter/MemoryDenyWriteExecute/PrivateUsers deliberately NOT set: this
      # exact binary (Grafana Alloy, Go) already crashed with SIGSYS from
      # SystemCallFilter=@system-service on gcp-relay (alloy-client.nix).
      NoNewPrivileges = lib.mkDefault true;
      ProtectClock = lib.mkDefault true;
      ProtectKernelLogs = lib.mkDefault true;
      ProtectKernelModules = lib.mkDefault true;
      ProtectKernelTunables = lib.mkDefault true;
      ProtectControlGroups = lib.mkDefault true;
      ProtectHostname = lib.mkDefault true;
      RestrictNamespaces = lib.mkDefault true;
      RestrictSUIDSGID = lib.mkDefault true;
      LockPersonality = lib.mkDefault true;
      RestrictRealtime = lib.mkDefault true;
      ProtectProc = lib.mkDefault "invisible";
      ProcSubset = lib.mkDefault "pid";
      UMask = lib.mkDefault "0077";
      RemoveIPC = lib.mkDefault true;
      # ProtectSystem/ProtectHome not set: alloy reads /var/log/traefik/access.log
      # outside any StateDirectory it owns — needs explicit ReadOnlyPaths first.
    };
  };
}
