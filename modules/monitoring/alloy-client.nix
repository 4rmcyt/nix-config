{
  config,
  lib,
  ...
}: {
  options.my.alloyClient = {
    enable = lib.mkEnableOption "Grafana Alloy log shipper (journal → remote Loki)";
    lokiUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://${config.my.network.hosts.homeserver_lan}:${toString config.my.network.ports.loki}/loki/api/v1/push";
      description = "Loki push endpoint.";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Value for the 'host' label sent to Loki.";
    };
  };

  config = lib.mkIf config.my.alloyClient.enable {
    services.alloy.enable = true;

    environment.etc."alloy/config.alloy".text = ''
      loki.write "default" {
        endpoint {
          url = "${config.my.alloyClient.lokiUrl}"
        }
      }

      loki.relabel "journal" {
        forward_to = []
        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
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
          host = "${config.my.alloyClient.hostname}",
        }
      }

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

    systemd.services.alloy.serviceConfig.SupplementaryGroups = ["systemd-journal"];
  };
}
