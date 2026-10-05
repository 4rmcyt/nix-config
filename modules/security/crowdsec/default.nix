{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.crowdsec;
  defaultLapiUrl = "http://127.0.0.1:${toString config.my.network.ports.crowdsec-lapi}";
  isRemoteLapi = cfg.nftables.lapiUrl != defaultLapiUrl;

  crowdsecPlugin = pkgs.fetchFromGitHub {
    owner = "maxlerebourg";
    repo = "crowdsec-bouncer-traefik-plugin";
    rev = "v1.7.1";
    hash = "sha256-hefOKDVsBxn+rCAylPHqbCNfPMbU/vtO4QpiftIPcUU=";
  };

  geoblockPlugin = pkgs.fetchFromGitHub {
    owner = "david-garcia-garcia";
    repo = "traefik-geoblock";
    rev = "v1.2.1";
    hash = "sha256-xo/4BxgjsrLEy1w/fHnGmZFrPRmza3OzBoTTWxqbwCY=";
  };
in {
  options.my.crowdsec = {
    traefik.enable = lib.mkEnableOption "CrowdSec Traefik bouncer plugin wiring";
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
    nftables = {
      enable = lib.mkEnableOption "CrowdSec nftables firewall bouncer";
      lapiUrl = lib.mkOption {
        type = lib.types.str;
        default = defaultLapiUrl;
        description = "CrowdSec LAPI URL (local or remote via Tailscale).";
      };
      secretsFile = lib.mkOption {
        type = lib.types.path;
        default = ../../../secrets/crowdsec.yaml;
        description = "Sops file containing crowdsec_bouncer_key_nftables.";
      };
    };
  };

  config = {
    sops.secrets.crowdsec_bouncer_key = lib.mkIf cfg.traefik.enable {
      sopsFile = ../../../secrets/crowdsec.yaml;
      owner = "traefik";
      group = "traefik";
      mode = "0400";
    };

    sops.secrets.crowdsec_bouncer_key_nftables = lib.mkIf cfg.nftables.enable {
      sopsFile = cfg.nftables.secretsFile;
      owner = "root";
      mode = "0400";
    };

    # tmpfiles-resetup skips crowdsec subdirs (unsafe path transition on DynamicUser's
    # nobody-owned /var/lib/private/crowdsec) — StateDirectory lets systemd manage them instead.
    systemd.services.crowdsec.serviceConfig.StateDirectory = lib.mkIf (!isRemoteLapi) (lib.mkForce [
      "crowdsec"
      "crowdsec/state"
      "crowdsec/state/hub"
    ]);

    # ExecStartPre's config test linearly scans the on-disk journal; right after boot
    # that hits a cold page cache and can exceed the default 90s TimeoutStartSec.
    # The victorialogs datasource gives up if VictoriaLogs isn't answering when crowdsec starts.
    systemd.services.crowdsec.after = lib.mkIf cfg.remoteCaddy.enable ["victorialogs.service"];
    systemd.services.crowdsec.wants = lib.mkIf cfg.remoteCaddy.enable ["victorialogs.service"];
    systemd.services.crowdsec.serviceConfig.TimeoutStartSec = lib.mkIf (!isRemoteLapi) "5min";
    systemd.services.crowdsec.serviceConfig.Restart = lib.mkIf (!isRemoteLapi) "on-failure";
    systemd.services.crowdsec.serviceConfig.RestrictSUIDSGID = lib.mkIf (!isRemoteLapi) true;
    systemd.services.crowdsec.serviceConfig.ProtectKernelTunables = lib.mkIf (!isRemoteLapi) true;
    systemd.services.crowdsec.serviceConfig.ProtectControlGroups = lib.mkIf (!isRemoteLapi) true;
    systemd.services.crowdsec.serviceConfig.ProtectKernelModules = lib.mkIf (!isRemoteLapi) true;
    systemd.services.crowdsec.serviceConfig.ProtectKernelLogs = lib.mkIf (!isRemoteLapi) true;
    systemd.services.crowdsec.serviceConfig.LockPersonality = lib.mkIf (!isRemoteLapi) true;
    systemd.services.crowdsec.serviceConfig.RestrictRealtime = lib.mkIf (!isRemoteLapi) true;
    systemd.services.crowdsec.serviceConfig.RestrictNamespaces = lib.mkIf (!isRemoteLapi) true;
    systemd.services.crowdsec.serviceConfig.SystemCallArchitectures = lib.mkIf (!isRemoteLapi) "native";

    services.crowdsec = lib.mkIf (!isRemoteLapi) {
      enable = true;

      hub.collections =
        [
          "crowdsecurity/linux"
          "crowdsecurity/sshd"
        ]
        ++ lib.optionals cfg.traefik.enable ["crowdsecurity/traefik"]
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
        ++ lib.optionals cfg.traefik.enable [
          {
            filenames = ["/var/log/traefik/access.log"];
            labels.type = "traefik";
          }
        ]
        ++ lib.optionals cfg.caddy.enable [
          {
            source = "journalctl";
            journalctl_filter = ["_SYSTEMD_UNIT=caddy.service"];
            labels.type = "caddy";
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

    environment.etc."crowdsec/parsers/s02-enrich/tailscale-whitelist.yaml" = lib.mkIf (!isRemoteLapi) {
      user = "crowdsec";
      group = "crowdsec";
      mode = "0640";
      text = ''
        name: tailscale-whitelist
        description: "Whitelist Tailscale CGNAT range"
        filter: "evt.Meta.source_ip startsWith '100.'"
        whitelist:
          reason: "Tailscale CGNAT"
          cidr:
            - "${config.my.network.subnets.tailscale}"
      '';
    };

    environment.etc."crowdsec/postoverflows/s01-whitelist/local-trusted-networks.yaml" = lib.mkIf (!isRemoteLapi) {
      user = "crowdsec";
      group = "crowdsec";
      mode = "0640";
      text = ''
        name: local-trusted-networks
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
      settings.api_url = cfg.nftables.lapiUrl;
    };

    networking.nftables.enable = lib.mkIf cfg.nftables.enable true;

    systemd.tmpfiles.rules = lib.mkIf cfg.traefik.enable [
      "d /var/lib/traefik/plugins-local 0750 traefik traefik -"
      "d /var/lib/traefik/plugins-local/src 0750 traefik traefik -"
      "d /var/lib/traefik/plugins-local/src/github.com 0750 traefik traefik -"
      "d /var/lib/traefik/plugins-local/src/github.com/maxlerebourg 0750 traefik traefik -"
      "d /var/lib/traefik/plugins-local/src/github.com/david-garcia-garcia 0750 traefik traefik -"
      "L+ /var/lib/traefik/plugins-local/src/github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin - - - - ${crowdsecPlugin}"
      "L+ /var/lib/traefik/plugins-local/src/github.com/david-garcia-garcia/traefik-geoblock - - - - ${geoblockPlugin}"
    ];
  };
}
