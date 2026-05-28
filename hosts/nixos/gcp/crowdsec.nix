{
  config,
  pkgs,
  ...
}: let
  bouncerKeyFile = config.sops.secrets.gcp.path;
in {
  sops.secrets.gcp = {
    sopsFile = ../../../secrets/gcp.yaml;
    owner = "root";
    mode = "0400";
  };

  # CrowdSec agent — parses SSH and Caddy logs
  services.crowdsec = {
    enable = true;

    hub.collections = [
      "crowdsecurity/caddy"
      "crowdsecurity/linux"
      "crowdsecurity/sshd"
    ];

    settings.general.api.server = {
      enable = true;
      listen_uri = "127.0.0.1:8088";
    };

    settings.lapi.credentialsFile = "/var/lib/crowdsec/state/lapi-credentials.yaml";

    localConfig.acquisitions = [
      {
        source = "journalctl";
        journalctl_filter = ["_SYSTEMD_UNIT=sshd.service"];
        labels.type = "syslog";
      }
      {
        source = "journalctl";
        journalctl_filter = ["_SYSTEMD_UNIT=caddy.service"];
        labels.type = "caddy";
      }
    ];
  };

  # nftables firewall bouncer
  # Workaround for nixpkgs#476253: must start after both nftables and crowdsec
  services.crowdsec-firewall-bouncer = {
    enable = true;
    settings = {
      mode = "nftables";
      api_key_path = "/run/crowdsec-bouncer/api_key";
      api_url = "http://127.0.0.1:8088";
    };
  };

  # Write bouncer API key from sops secret before the bouncer starts
  systemd.services.crowdsec-firewall-bouncer-key = {
    description = "Write CrowdSec bouncer API key to /run";
    before = ["crowdsec-firewall-bouncer.service"];
    wantedBy = ["crowdsec-firewall-bouncer.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "crowdsec-bouncer-key" ''
        install -d -m 0700 /run/crowdsec-bouncer
        install -m 0600 ${bouncerKeyFile} /run/crowdsec-bouncer/api_key
      '';
    };
  };

  systemd.services.crowdsec-firewall-bouncer = {
    after = ["nftables.service" "crowdsec.service"];
    requires = ["crowdsec.service"];
  };

  # Whitelist: Tailscale CGNAT is not RFC1918 — must be explicit
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

  environment.etc."crowdsec/postoverflows/s01-whitelist/local-trusted-networks.yaml" = {
    user = "crowdsec";
    group = "crowdsec";
    mode = "0640";
    text = ''
      name: local-trusted-networks
      description: "Whitelist loopback and Tailscale"
      whitelist:
        reason: "trusted network"
        ip:
          - "127.0.0.1"
        cidr:
          - "100.64.0.0/10"
    '';
  };

  # nftables must be enabled for the firewall bouncer
  networking.nftables.enable = true;
}
