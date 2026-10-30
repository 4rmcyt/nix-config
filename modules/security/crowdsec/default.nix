{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.crowdsec;
  cs = config.services.crowdsec;
  inherit (config.my.network) ports subnets;
  cscli = lib.getExe' cs.package "cscli";
  journal = filter: {
    source = "journalctl";
    journalctl_filter = filter;
    # journalctl emits syslog-style lines; syslog-logs strips the prefix and sets `program` for the app parsers.
    labels.type = "syslog";
  };
  registerBouncers = pkgs.writeShellScript "crowdsec-bouncers-register" (lib.concatStrings (lib.mapAttrsToList (name: _: ''
      if ! ${cscli} bouncers list -o json | ${lib.getExe pkgs.jq} -e --arg n ${lib.escapeShellArg name} 'any(.[]; .name == $n)' >/dev/null; then
        ${cscli} bouncers add ${lib.escapeShellArg name} --key "$(<"$CREDENTIALS_DIRECTORY/${name}")"
      fi
    '')
    cfg.bouncers));
  # Must load last in appsec_configs: cancels the per-request WAF alerts that burn the Console quota; events still ban.
  noWafAlerts = (pkgs.formats.yaml {}).generate "no-waf-alerts.yaml" {
    name = "local/no-waf-alerts";
    # The last config's scalars override earlier ones unconditionally.
    default_remediation = "ban";
    inband.on_match = [{apply = ["CancelAlert()"];}];
    outofband.on_match = [{apply = ["CancelAlert()"];}];
  };
in {
  options.my.crowdsec = {
    caddy.enable = lib.mkEnableOption "CrowdSec Caddy log acquisition";
    appsec.enable = lib.mkEnableOption "CrowdSec AppSec (WAF) component on localhost";
    homeAssistant.enable = lib.mkEnableOption "CrowdSec Home Assistant failed-login detection";
    ntfy.enable = lib.mkEnableOption "CrowdSec ntfy failed-auth detection";
    remoteCaddy = {
      enable = lib.mkEnableOption "CrowdSec acquisition of remote Caddy access logs from VictoriaLogs";
      query = lib.mkOption {
        type = lib.types.str;
        description = "LogsQL query selecting the remote Caddy journal lines (tail mode).";
        example = ''{_HOSTNAME="gcp-relay", _SYSTEMD_UNIT="caddy.service"} remote_ip:="100.64.0.5"'';
      };
    };
    nftables.enable = lib.mkEnableOption "CrowdSec nftables firewall bouncer";
    bouncers = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {};
      description = "Bouncer name → API key file; registered in the LAPI database if missing.";
    };
  };

  config = lib.mkMerge [
    {
      services.crowdsec = {
        enable = true;
        hub.collections = ["crowdsecurity/linux" "crowdsecurity/sshd"];

        settings = {
          config = {
            # Pre-rewrite layout: DB, credentials and hub stay here instead of the default /var/lib/crowdsec/data.
            config_paths.data_dir = "/var/lib/crowdsec/state";
            api.client.credentials_path = "/var/lib/crowdsec/state/lapi-credentials.yaml";
            api.server = {
              listen_uri = "0.0.0.0:${toString ports.crowdsec-lapi}";
              # Non-null: crowdsec-setup registers with CAPI, which pulls the community blocklist and shares signals.
              online_client.credentials_path = "/var/lib/crowdsec/state/capi-credentials.yaml";
            };
          };

          console.configuration = {
            share_manual_decisions = true;
            share_custom = true;
            share_tainted = true;
            share_context = true;
          };

          # Module defaults plus escalation: each repeat ban for the same value lasts 4h longer.
          profiles = map (scope: {
            name = "default_${lib.toLower scope}_remediation";
            filters = ["Alert.Remediation == true && Alert.GetScope() == '${scope}'"];
            decisions = [
              {
                type = "ban";
                duration = "4h";
              }
            ];
            # No `%`: profiles.yaml is written through a tmpfiles argument, where `%d` is a specifier.
            duration_expr = "string((GetDecisionsCount(Alert.GetValue()) + 1) * 4) + 'h'";
            on_success = "break";
          }) ["Ip" "Range"];

          acquisitions = [
            (journal ["_TRANSPORT=syslog" "SYSLOG_IDENTIFIER=sshd"])
            (journal ["_TRANSPORT=syslog" "SYSLOG_IDENTIFIER=sshd-session"])
          ];

          # Trusted events are dropped before they reach any bucket.
          parsers.s02Enrich = [
            {
              name = "local/trusted-networks";
              description = "Whitelist LAN, Tailscale and Cloudflare IPs";
              whitelist = {
                reason = "trusted network";
                ip = ["127.0.0.1" config.my.network.gateway];
                cidr = [subnets.trusted "10.0.0.0/8" subnets.tailscale] ++ subnets.cloudflare;
              };
            }
          ];
        };
      };

      systemd.services.crowdsec.serviceConfig = {
        # ExecStartPre's config test scans the journal; cold page cache after boot exceeds the default 90s.
        TimeoutStartSec = "5min";
        RestrictSUIDSGID = true;
      };
    }

    (lib.mkIf (cfg.bouncers != {}) {
      # Bouncer keys live in sops, not the LAPI DB: re-register missing ones inside crowdsec's own sandbox.
      systemd.services.crowdsec.serviceConfig = {
        LoadCredential = lib.mapAttrsToList (name: path: "${name}:${path}") cfg.bouncers;
        # "-": a failed registration is logged but doesn't take crowdsec down.
        ExecStartPost = "-${registerBouncers}";
      };
    })

    (lib.mkIf (cfg.caddy.enable || cfg.remoteCaddy.enable) {
      services.crowdsec.hub.collections = ["crowdsecurity/caddy"];
    })

    (lib.mkIf cfg.caddy.enable {
      services.crowdsec.settings.acquisitions = [(journal ["_SYSTEMD_UNIT=caddy.service"])];
    })

    (lib.mkIf cfg.remoteCaddy.enable {
      services.crowdsec.settings.acquisitions = [
        {
          source = "victorialogs";
          mode = "tail";
          url = "http://127.0.0.1:${toString ports.victorialogs}";
          inherit (cfg.remoteCaddy) query;
          labels.type = "caddy";
        }
      ];
      # The victorialogs datasource gives up if VictoriaLogs isn't answering when crowdsec starts.
      systemd.services.crowdsec = {
        after = ["victorialogs.service"];
        wants = ["victorialogs.service"];
      };
    })

    (lib.mkIf cfg.appsec.enable {
      services.crowdsec = {
        hub.collections = [
          "crowdsecurity/appsec-virtual-patching"
          "crowdsecurity/appsec-generic-rules"
          "crowdsecurity/appsec-crs"
        ];
        settings.acquisitions = [
          {
            source = "appsec";
            name = "caddy-appsec";
            # appsec-default: in-band vpatch + generic; crs: out-of-band OWASP CRS; no-waf-alerts last.
            appsec_configs = ["crowdsecurity/appsec-default" "crowdsecurity/crs" "local/no-waf-alerts"];
            listen_addr = "127.0.0.1:${toString ports.crowdsec-appsec}";
            labels.type = "appsec";
          }
        ];
      };
      # The module only links its own files; cscli also symlinks hub appsec-configs into this dir.
      systemd.tmpfiles.settings."10-crowdsec" = {
        "/etc/crowdsec/appsec-configs".d = {
          inherit (cs) user group;
          mode = "0700";
        };
        "/etc/crowdsec/appsec-configs/no-waf-alerts.yaml"."L+".argument = toString noWafAlerts;
      };
    })

    (lib.mkIf cfg.homeAssistant.enable {
      services.crowdsec = {
        hub.collections = ["crowdsecurity/home-assistant"];
        # SYSLOG_IDENTIFIER=homeassistant matches the parser's `program endsWith 'homeassistant'`.
        settings.acquisitions = [(journal ["CONTAINER_NAME=homeassistant"])];
      };
    })

    (lib.mkIf cfg.ntfy.enable {
      services.crowdsec = {
        hub.collections = ["Jgigantino31/ntfy"];
        settings.acquisitions = [(journal ["_SYSTEMD_UNIT=ntfy-sh.service"])];
      };
    })

    (lib.mkIf cfg.nftables.enable {
      sops.secrets.crowdsec_bouncer_key_nftables = {
        sopsFile = ../../../secrets/crowdsec.yaml;
        owner = "root";
        mode = "0400";
      };
      services.crowdsec-firewall-bouncer = {
        enable = true;
        registerBouncer.enable = false;
        secrets.apiKeyPath = config.sops.secrets.crowdsec_bouncer_key_nftables.path;
        settings.api_url = "http://127.0.0.1:${toString ports.crowdsec-lapi}";
      };
      networking.nftables.enable = true;
      my.crowdsec.bouncers.homeserver-nftables = config.sops.secrets.crowdsec_bouncer_key_nftables.path;
    })
  ];
}
