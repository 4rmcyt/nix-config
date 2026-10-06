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
in {
  options.my.crowdsec = {
    caddy.enable = lib.mkEnableOption "CrowdSec Caddy log acquisition";
    appsec.enable = lib.mkEnableOption "CrowdSec AppSec (WAF) component on localhost";
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
    systemd.services.crowdsec.serviceConfig = {
      # tmpfiles-resetup skips subdirs of DynamicUser's nobody-owned /var/lib/private/crowdsec; let systemd own them.
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
        ];

      settings.general.api.server = {
        enable = true;
        listen_uri = "0.0.0.0:${toString config.my.network.ports.crowdsec-lapi}";
      };

      settings.lapi.credentialsFile = "/var/lib/crowdsec/state/lapi-credentials.yaml";
      # Non-null makes the module run `cscli capi register` and pull the community blocklist (sharing on).
      settings.capi.credentialsFile = "/var/lib/crowdsec/state/capi-credentials.yaml";

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
            appsec_configs = ["crowdsecurity/appsec-default"];
            listen_addr = "127.0.0.1:${toString config.my.network.ports.crowdsec-appsec}";
            labels.type = "appsec";
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

    # Bouncer keys live in sops, not in the LAPI DB backup: re-register them after a state loss.
    systemd.services.crowdsec-bouncers-register = lib.mkIf (cfg.bouncers != {}) {
      description = "Register declared CrowdSec bouncers in the local API";
      wantedBy = ["multi-user.target"];
      after = ["crowdsec.service"];
      requires = ["crowdsec.service"];
      path = [pkgs.jq];
      script = lib.concatStrings (lib.mapAttrsToList (name: _: ''
          if ! ${cscli} bouncers list -o json | jq -e --arg n ${lib.escapeShellArg name} 'any(.[]; .name == $n)' >/dev/null; then
            ${cscli} bouncers add ${lib.escapeShellArg name} --key "$(cat "$CREDENTIALS_DIRECTORY/${name}")"
          fi
        '')
        cfg.bouncers);
      serviceConfig = {
        Type = "oneshot";
        # Same identity as crowdsec.service so cscli can open its state (mirrors nixpkgs' crowdsec-firewall-bouncer-register).
        User = cs.user;
        Group = cs.group;
        DynamicUser = true;
        StateDirectory = "crowdsec";
        LoadCredential = lib.mapAttrsToList (name: path: "${name}:${path}") cfg.bouncers;
      };
    };
  };
}
