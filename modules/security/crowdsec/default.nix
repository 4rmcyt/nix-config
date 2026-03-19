{
  config,
  pkgs,
  lib,
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
    ];
  };

  # ----------------------------------------------------------------
  # Traefik plugin sources (local — no internet required at startup)
  # ----------------------------------------------------------------
  systemd.tmpfiles.rules = [
    # CrowdSec bouncer plugin
    "L+ /var/lib/traefik/plugins-local/src/github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin - - - - ${crowdsecPlugin}"
    # Geoblock plugin
    "L+ /var/lib/traefik/plugins-local/src/github.com/david-garcia-garcia/traefik-geoblock - - - - ${geoblockPlugin}"
    # Geoblock DB directory (auto-update will populate it)
    "d /var/lib/traefik/geoblock 0750 traefik traefik -"
  ];
}
