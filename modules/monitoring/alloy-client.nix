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

    systemd.services.alloy.serviceConfig = {
      SupplementaryGroups = ["systemd-journal"];

      # nixpkgs' alloy module leaves CapabilityBoundingSet at the full
      # default set and AmbientCapabilities empty (verified via `systemctl
      # show alloy.service`) — it doesn't actually request any capability,
      # journal read access comes from the systemd-journal group above, not
      # a capability. All it does is tail the journal and push over HTTP.
      CapabilityBoundingSet = lib.mkForce "";
      RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX"];
      SystemCallArchitectures = lib.mkDefault "native";
      # SystemCallFilter=["@system-service"] and MemoryDenyWriteExecute=true
      # deliberately NOT set: both kill the process on violation by default
      # (SIGSYS, not a catchable error), and alloy died that way on gcp-relay
      # (signal=killed status=31/SYS) — Grafana Alloy's Go runtime needs
      # something outside @system-service that wasn't worth reverse-
      # engineering via strace on a remote host with no other access.

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
      # PrivateUsers also NOT set — same class of risk as
      # SystemCallFilter/MemoryDenyWriteExecute above (namespace-related
      # surprises already broke caddy/crowdsec-firewall-bouncer's network
      # capabilities elsewhere in this pass); SupplementaryGroups-based
      # journal read access is exactly the kind of thing that can silently
      # break under a private user namespace, not worth the risk for a log
      # shipper.
      # No IPAddressDeny/Allow — Loki push endpoint varies per host
      # (config.my.alloyClient.lokiUrl), not worth hardcoding an allowlist
      # here for a log shipper.
    };
  };
}
