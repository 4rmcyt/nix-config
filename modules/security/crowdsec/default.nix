{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.crowdsec;
  isRemoteLapi = cfg.nftables.lapiUrl != "http://127.0.0.1:8088";

  crowdsecPlugin = pkgs.fetchFromGitHub {
    owner = "maxlerebourg";
    repo = "crowdsec-bouncer-traefik-plugin";
    rev = "v1.6.0";
    hash = "sha256-Wf2R2vgwBzUxuk96njtGFu8w7mdP5bm+5ZuO3D1+AbA=";
  };

  geoblockPlugin = pkgs.fetchFromGitHub {
    owner = "david-garcia-garcia";
    repo = "traefik-geoblock";
    rev = "v1.1.4";
    hash = "sha256-qgLM6nrlDXLS7OsLw6cDKjhx9B+CnJR4TB32pg/MvEo=";
  };
in {
  options.my.crowdsec = {
    traefik.enable = lib.mkEnableOption "CrowdSec Traefik bouncer plugin wiring";
    caddy.enable = lib.mkEnableOption "CrowdSec Caddy log acquisition";
    nftables = {
      enable = lib.mkEnableOption "CrowdSec nftables firewall bouncer";
      lapiUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8088";
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

    # tmpfiles-resetup skips crowdsec subdirs due to unsafe path transition on /var/lib/private/crowdsec
    # (owned by nobody — normal for DynamicUser). StateDirectory lets systemd manage it correctly.
    systemd.services.crowdsec.serviceConfig.StateDirectory = lib.mkIf (!isRemoteLapi) (lib.mkDefault "crowdsec");

    services.crowdsec = lib.mkIf (!isRemoteLapi) {
      enable = true;

      hub.collections =
        [
          "crowdsecurity/linux"
          "crowdsecurity/sshd"
        ]
        ++ lib.optionals cfg.traefik.enable ["crowdsecurity/traefik"]
        ++ lib.optionals cfg.caddy.enable ["crowdsecurity/caddy"];

      settings.general.api.server = {
        enable = true;
        listen_uri = "0.0.0.0:8088";
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
            - "100.64.0.0/10"
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
            - "192.168.1.1"
          cidr:
            - "192.168.1.0/24"
            - "10.0.0.0/8"
            - "100.64.0.0/10"
            - "173.245.48.0/20"
            - "103.21.244.0/22"
            - "103.22.200.0/22"
            - "103.31.4.0/22"
            - "141.101.64.0/18"
            - "108.162.192.0/18"
            - "190.93.240.0/20"
            - "188.114.96.0/20"
            - "197.234.240.0/22"
            - "198.41.128.0/17"
            - "162.158.0.0/15"
            - "104.16.0.0/13"
            - "104.24.0.0/14"
            - "172.64.0.0/13"
            - "131.0.72.0/22"
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
