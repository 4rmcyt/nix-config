{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.crowdsec;
  cs = config.services.crowdsec;
  # nixpkgs' cscli wrapper breaks under DynamicUser and /etc/crowdsec/config.yaml doesn't exist; rebuild the module's config path.
  cscli = "${lib.getExe' cs.package "cscli"} -c ${(pkgs.formats.yaml {}).generate "crowdsec.yaml" cs.settings.general}";
  hasBouncers = cfg.bouncers != {};
  registerBouncers = pkgs.writeShellScript "crowdsec-bouncers-register" (lib.concatStrings (lib.mapAttrsToList (name: _: ''
      if ! ${cscli} bouncers list -o json | ${lib.getExe pkgs.jq} -e --arg n ${lib.escapeShellArg name} 'any(.[]; .name == $n)' >/dev/null; then
        ${cscli} bouncers add ${lib.escapeShellArg name} --key "$(<"$CREDENTIALS_DIRECTORY/${name}")"
      fi
    '')
    cfg.bouncers));
  svc = config.systemd.services.crowdsec.serviceConfig;
  # Manual cscli inside crowdsec.service's sandbox: new state files land on the idmapped StateDirectory, not as root.
  cscliSandboxed = pkgs.writeShellScriptBin "cscli" ''
    exec ${config.systemd.package}/bin/systemd-run --quiet --pipe --pty --wait --collect --service-type=exec \
      -p User=${cs.user} -p Group=${cs.group} -p DynamicUser=yes -p UMask=0077 \
      -p StateDirectory=${lib.escapeShellArg (lib.concatStringsSep " " svc.StateDirectory)} \
      -p ReadWritePaths=${lib.escapeShellArg (lib.concatStringsSep " " svc.ReadWritePaths)} \
      -E PATH=${lib.makeBinPath [cs.package]} \
      ${cscli} "$@"
  '';
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

  config = {
    sops.secrets.crowdsec_bouncer_key_nftables = lib.mkIf cfg.nftables.enable {
      sopsFile = ../../../secrets/crowdsec.yaml;
      owner = "root";
      mode = "0400";
    };

    # The victorialogs datasource gives up if VictoriaLogs isn't answering when crowdsec starts.
    systemd.services.crowdsec.after = lib.mkIf cfg.remoteCaddy.enable ["victorialogs.service"];
    systemd.services.crowdsec.wants = lib.mkIf cfg.remoteCaddy.enable ["victorialogs.service"];
    # hiPrio: system-path ignores collisions, so this must outrank nixpkgs' `sudo -u crowdsec` wrapper.
    environment.systemPackages = [(lib.hiPrio cscliSandboxed)];

    # nixpkgs' `d … crowdsec crowdsec` rules re-chown state/ to 949 on every tmpfiles run, breaking new hub data files.
    systemd.tmpfiles.settings."10-crowdsec" = {
      "/var/lib/crowdsec/state" = lib.mkForce {};
      "/var/lib/crowdsec/state/hub/" = lib.mkForce {};
      # cscli symlinks hub appsec-configs here; keep it crowdsec-owned when environment.etc creates it first.
      "/etc/crowdsec/appsec-configs" = lib.mkIf cfg.appsec.enable {
        d = {
          inherit (cs) user;
          inherit (cs) group;
          mode = "0700";
        };
      };
    };

    systemd.services.crowdsec.serviceConfig = {
      # DynamicUser state dirs are created and owned by systemd, not tmpfiles.
      StateDirectory = lib.mkForce [
        "crowdsec"
        "crowdsec/state"
        "crowdsec/state/hub"
      ];
      # ExecStartPre's config test scans the journal; cold page cache after boot exceeds the default 90s.
      TimeoutStartSec = "5min";
      Restart = "on-failure";
      RestrictSUIDSGID = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
      SystemCallArchitectures = "native";
      # Bouncer keys live in sops, not the LAPI DB: re-register missing ones in crowdsec's own sandbox.
      LoadCredential = lib.mkIf hasBouncers (lib.mapAttrsToList (name: path: "${name}:${path}") cfg.bouncers);
      # "-": a failed registration is logged but doesn't take crowdsec down.
      ExecStartPost = lib.mkIf hasBouncers "-${registerBouncers}";
    };

    services.crowdsec = {
      enable = true;

      hub.collections =
        [
          "crowdsecurity/linux"
          "crowdsecurity/sshd"
        ]
        ++ lib.optionals (cfg.caddy.enable || cfg.remoteCaddy.enable) ["crowdsecurity/caddy"]
        ++ lib.optionals cfg.appsec.enable [
          "crowdsecurity/appsec-virtual-patching"
          "crowdsecurity/appsec-generic-rules"
          "crowdsecurity/appsec-crs"
        ]
        ++ lib.optionals cfg.homeAssistant.enable ["crowdsecurity/home-assistant"]
        ++ lib.optionals cfg.ntfy.enable ["Jgigantino31/ntfy"];

      settings.general.api.server = {
        enable = true;
        listen_uri = "0.0.0.0:${toString config.my.network.ports.crowdsec-lapi}";
      };

      settings.lapi.credentialsFile = "/var/lib/crowdsec/state/lapi-credentials.yaml";
      # Non-null makes the module run `cscli capi register` and pull the community blocklist (sharing on).
      settings.capi.credentialsFile = "/var/lib/crowdsec/state/capi-credentials.yaml";
      # console.yaml is in the store, so `cscli console enroll` can't write its share flags; set them here.
      settings.console.configuration = {
        share_manual_decisions = true;
        share_custom = true;
        share_tainted = true;
        share_context = true;
      };

      # Module defaults plus escalation: each repeat ban for the same value lasts 4h longer.
      localConfig.profiles = map (scope: {
        name = "default_${lib.toLower scope}_remediation";
        filters = ["Alert.Remediation == true && Alert.GetScope() == '${scope}'"];
        decisions = [
          {
            type = "ban";
            duration = "4h";
          }
        ];
        duration_expr = "Sprintf('%dh', (GetDecisionsCount(Alert.GetValue()) + 1) * 4)";
        on_success = "break";
      }) ["Ip" "Range"];

      localConfig.acquisitions =
        [
          {
            source = "journalctl";
            journalctl_filter = [
              "_TRANSPORT=syslog"
              "SYSLOG_IDENTIFIER=sshd"
            ];
            labels.type = "syslog";
          }
          {
            source = "journalctl";
            journalctl_filter = [
              "_TRANSPORT=syslog"
              "SYSLOG_IDENTIFIER=sshd-session"
            ];
            labels.type = "syslog";
          }
        ]
        ++ lib.optionals cfg.caddy.enable [
          {
            source = "journalctl";
            journalctl_filter = ["_SYSTEMD_UNIT=caddy.service"];
            # journalctl emits syslog-style lines; syslog-logs strips the prefix and sets program=caddy for caddy-logs.
            labels.type = "syslog";
          }
        ]
        ++ lib.optionals cfg.appsec.enable [
          {
            source = "appsec";
            name = "caddy-appsec";
            # appsec-default: in-band vpatch + generic; crs: out-of-band OWASP CRS, bans on repeat hits.
            # Must stay last: it cancels the per-request WAF alerts both configs above send.
            appsec_configs = ["crowdsecurity/appsec-default" "crowdsecurity/crs" "local/no-waf-alerts"];
            listen_addr = "127.0.0.1:${toString config.my.network.ports.crowdsec-appsec}";
            labels.type = "appsec";
          }
        ]
        ++ lib.optionals cfg.homeAssistant.enable [
          {
            source = "journalctl";
            journalctl_filter = ["CONTAINER_NAME=homeassistant"];
            # SYSLOG_IDENTIFIER=homeassistant matches the parser's `program endsWith 'homeassistant'`.
            labels.type = "syslog";
          }
        ]
        ++ lib.optionals cfg.ntfy.enable [
          {
            source = "journalctl";
            journalctl_filter = ["_SYSTEMD_UNIT=ntfy-sh.service"];
            labels.type = "syslog";
          }
        ]
        ++ lib.optionals cfg.remoteCaddy.enable [
          {
            source = "victorialogs";
            mode = "tail";
            url = "http://127.0.0.1:${toString config.my.network.ports.victorialogs}";
            inherit (cfg.remoteCaddy) query;
            labels.type = "caddy";
          }
        ];
    };

    # Parser stage: trusted events are dropped before reaching buckets.
    # Per-request WAF alerts burn the Console quota; events stay, so appsec-vpatch / appsec-outofband still ban.
    environment.etc."crowdsec/appsec-configs/no-waf-alerts.yaml" = lib.mkIf cfg.appsec.enable {
      user = "crowdsec";
      group = "crowdsec";
      mode = "0640";
      # Scalars from the last config override earlier ones unconditionally, so default_remediation must be set.
      text = ''
        name: local/no-waf-alerts
        default_remediation: ban
        inband:
          on_match:
            - apply:
                - CancelAlert()
        outofband:
          on_match:
            - apply:
                - CancelAlert()
      '';
    };

    environment.etc."crowdsec/parsers/s02-enrich/local-trusted-networks.yaml" = {
      user = "crowdsec";
      group = "crowdsec";
      mode = "0640";
      text = ''
        name: local/trusted-networks
        description: "Whitelist LAN, Tailscale and Cloudflare IPs"
        whitelist:
          reason: "trusted network"
          ip:
            - "127.0.0.1"
            - "${config.my.network.gateway}"
          cidr:
            - "${config.my.network.subnets.trusted}"
            - "10.0.0.0/8"
            - "${config.my.network.subnets.tailscale}"
        ${lib.concatMapStringsSep "\n" (cidr: "    - \"${cidr}\"") config.my.network.subnets.cloudflare}
      '';
    };

    services.crowdsec-firewall-bouncer = lib.mkIf cfg.nftables.enable {
      enable = true;
      registerBouncer.enable = false;
      secrets.apiKeyPath = config.sops.secrets.crowdsec_bouncer_key_nftables.path;
      settings.api_url = "http://127.0.0.1:${toString config.my.network.ports.crowdsec-lapi}";
    };

    networking.nftables.enable = lib.mkIf cfg.nftables.enable true;

    my.crowdsec.bouncers.homeserver-nftables = lib.mkIf cfg.nftables.enable config.sops.secrets.crowdsec_bouncer_key_nftables.path;
  };
}
