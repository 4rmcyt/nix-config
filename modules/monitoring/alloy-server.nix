_: {
  # --- Grafana Alloy Log Shipper (server-side: reads Traefik access log +
  # the systemd journal, ships to the local Loki instance) ---
  services.alloy.enable = true;

  environment.etc."alloy/config.alloy".text = ''
    // ── Loki sink ────────────────────────────────────────────────
    loki.write "default" {
      endpoint {
        url = "http://localhost:3100/loki/api/v1/push"
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
    after = ["geoip-update.service"];
    serviceConfig.SupplementaryGroups = ["systemd-journal"];
  };
}
