{
  config,
  lib,
  ...
}: let
  cfg = config.my.unbound;
  inherit (config.my.defaults) domain gcpRelayIp nextdnsProfileId;
  inherit (config.my.network.hosts) homeserver_lan homeserver_ts;
in {
  options.my.unbound = {
    enable = lib.mkEnableOption "Unbound split DNS for Tailscale";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Interfaces to listen on.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.unbound = {
      after = ["tailscale.service" "tailscale-autoconnect.service"];
      wants = ["tailscale.service"];
    };

    services.unbound = {
      enable = true;
      resolveLocalQueries = false;
      settings = {
        server = {
          interface = cfg.interfaces;
          access-control =
            ["127.0.0.1/8 allow"]
            ++ map (subnet: "${subnet} allow") [
              config.my.network.subnets.trusted
              config.my.network.subnets.iot
              config.my.network.subnets.media
              config.my.network.subnets.work
              config.my.network.subnets.tailscale
            ];
          tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";
          cache-max-ttl = 86400;
          cache-min-ttl = 300;
          neg-cache-size = "4m";
          hide-identity = true;
          hide-version = true;

          # domain has public DNSSEC delegation, but ts.domain is a private zone with no
          # real signature — the validator would mark it bogus/SERVFAIL without this.
          domain-insecure = ["${domain}"];

          # ts.domain must be carved out with "transparent": since it's a subzone of
          # domain, redirect would otherwise swallow it too, and ts.domain needs to fall
          # through to the Tailscale stub resolver for per-node MagicDNS records.
          local-zone = [
            ''"ts.${domain}." transparent''
            ''"${domain}." redirect''
            ''"hs.${domain}." static''
            ''"hp.${domain}." static''
          ];
          local-data = [
            ''"${domain}. A ${homeserver_ts}"''
            ''"${domain}. A ${homeserver_lan}"''
            ''"hs.${domain}. A ${gcpRelayIp}"''
            ''"hp.${domain}. A ${gcpRelayIp}"''
          ];
        };

        forward-zone = [
          {
            name = ".";
            forward-tls-upstream = true;
            forward-addr = [
              "45.90.28.163@853#${nextdnsProfileId}.dns.nextdns.io"
              "45.90.30.163@853#${nextdnsProfileId}.dns.nextdns.io"
            ];
          }
          {
            name = "ts.${domain}.";
            forward-addr = ["100.100.100.100"];
          }
        ];
      };
    };
  };
}
