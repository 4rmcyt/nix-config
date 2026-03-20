{
  pkgs,
  ...
}: let
  crowdsecPlugin = pkgs.fetchFromGitHub {
    owner = "maxlerebourg";
    repo = "crowdsec-bouncer-traefik-plugin";
    rev = "v1.5.1";
    hash = "sha256-w4tQjJjcHg6P5ew7kkj4j5cduLIrs5BiQlvxkJFi6So=";
  };

  geoblockPlugin = pkgs.fetchFromGitHub {
    owner = "david-garcia-garcia";
    repo = "traefik-geoblock";
    rev = "v1.1.4";
    hash = "sha256-qgLM6nrlDXLS7OsLw6cDKjhx9B+CnJR4TB32pg/MvEo=";
  };
in {
  # ----------------------------------------------------------------
  # Sops secrets
  # ----------------------------------------------------------------
  sops.secrets.crowdsec_bouncer_key = {
    sopsFile = ../../../secrets/crowdsec.yaml;
    owner = "traefik";
    group = "traefik";
    mode = "0400";
  };

  # ----------------------------------------------------------------
  # CrowdSec agent
  # ----------------------------------------------------------------
  services.crowdsec = {
    enable = true;

    hub.collections = [
      "crowdsecurity/traefik"
      "crowdsecurity/linux"
      "crowdsecurity/sshd"
    ];

    settings.general.api.server = {
      enable = true;
      listen_uri = "127.0.0.1:8088";
    };

    # lapi.credentialsFile must point to a writable path — CrowdSec
    # auto-generates this file on first run via `cscli machine add`
    settings.lapi.credentialsFile = "/var/lib/crowdsec/state/lapi-credentials.yaml";

    localConfig.acquisitions = [
      {
        # Traefik JSON access log
        filenames = ["/var/log/traefik/access.log"];
        labels.type = "traefik";
      }
      {
        # SSH via journald
        source = "journalctl";
        journalctl_filter = ["_SYSTEMD_UNIT=sshd.service"];
        labels.type = "syslog";
      }
      # Cowrie acquisition disabled
      # {
      #   filenames = ["/var/log/cowrie/cowrie.json"];
      #   labels.type = "cowrie";
      #   poll_without_inotify = true;
      #   max_buffer_size = 10485760;
      # }
    ];
  };

  # ----------------------------------------------------------------
  # Parser whitelist — written directly to avoid stale-symlink accumulation
  # (same issue as postoverflow: localConfig.parsers uses L+ symlinks that accumulate)
  # Tailscale CGNAT (100.64.0.0/10) is not RFC1918 — must be whitelisted explicitly
  # ----------------------------------------------------------------
  environment.etc."crowdsec/parsers/s02-enrich/tailscale-whitelist.yaml" = {
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

  # ----------------------------------------------------------------
  # Postoverflow whitelist — written directly to avoid stale-symlink accumulation
  # (the NixOS crowdsec module's localConfig.postOverflows.s01Whitelist uses
  # environment.etc with L+ symlinks that are never cleaned up across rebuilds)
  # ----------------------------------------------------------------
  environment.etc."crowdsec/postoverflows/s01-whitelist/local-trusted-networks.yaml" = {
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

  # ----------------------------------------------------------------
  # Traefik plugin sources (local — no internet required at startup)
  # Directories owned by traefik to satisfy systemd-tmpfiles path safety checks
  # ----------------------------------------------------------------
  systemd.tmpfiles.rules = [
    "d /var/lib/traefik/plugins-local 0750 traefik traefik -"
    "d /var/lib/traefik/plugins-local/src 0750 traefik traefik -"
    "d /var/lib/traefik/plugins-local/src/github.com 0750 traefik traefik -"
    "d /var/lib/traefik/plugins-local/src/github.com/maxlerebourg 0750 traefik traefik -"
    "d /var/lib/traefik/plugins-local/src/github.com/david-garcia-garcia 0750 traefik traefik -"
    "L+ /var/lib/traefik/plugins-local/src/github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin - - - - ${crowdsecPlugin}"
    "L+ /var/lib/traefik/plugins-local/src/github.com/david-garcia-garcia/traefik-geoblock - - - - ${geoblockPlugin}"
  ];
}
