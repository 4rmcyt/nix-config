{
  config,
  lib,
  ...
}: let
  cfg = config.my.unbound;
  inherit (config.my.defaults) domain homeserver_lan;
in {
  options.my.unbound = {
    enable = lib.mkEnableOption "Unbound split DNS for Tailscale";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Interfaces to listen on.";
    };

    tailscaleIp = lib.mkOption {
      type = lib.types.str;
      description = "Homeserver Tailscale IP for *.domain wildcard.";
    };

    gcpRelayIp = lib.mkOption {
      type = lib.types.str;
      description = "GCP relay static IP (for hs.* and hp.* overrides).";
    };

    nextdnsProfileId = lib.mkOption {
      type = lib.types.str;
      description = "NextDNS profile ID (e.g. abcdef).";
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
          access-control = [
            "127.0.0.1/8 allow"
            "192.168.0.0/16 allow"
            "100.64.0.0/10 allow"
          ];
          tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";
          cache-max-ttl = 86400;
          cache-min-ttl = 300;
          neg-cache-size = "4m";
          hide-identity = true;
          hide-version = true;

          # domain is a real registered name with public DNSSEC delegation.
          # The validator tries to build a chain of trust for ts.domain as if
          # it were a real public name, fails (private zone, no real
          # delegation/signature), and marks it bogus -> SERVFAIL. Tell the
          # validator to treat the whole domain as unsigned so local
          # overrides and the ts.domain forward both resolve.
          domain-insecure = ["${domain}"];

          # *.domain → homeserver (Tailscale IP + LAN IP)
          # ts.domain is a subzone of domain, so redirect covers it unless
          # carved out with "transparent" (nodefault only disables unbound's
          # own built-in default zones, it does not exempt a subzone from a
          # local-zone you configured yourself) — it must fall through to the
          # Tailscale stub resolver below, since it holds per-node MagicDNS
          # records (e.g. matebook.ts.domain) that vary per host.
          local-zone = [
            ''"ts.${domain}." transparent''
            ''"${domain}." redirect''
            ''"hs.${domain}." static''
            ''"hp.${domain}." static''
          ];
          local-data = [
            ''"${domain}. A ${cfg.tailscaleIp}"''
            ''"${domain}. A ${homeserver_lan}"''
            ''"hs.${domain}. A ${cfg.gcpRelayIp}"''
            ''"hp.${domain}. A ${cfg.gcpRelayIp}"''
          ];
        };

        forward-zone = [
          {
            name = ".";
            forward-tls-upstream = true;
            forward-addr = [
              "45.90.28.163@853#${cfg.nextdnsProfileId}.dns.nextdns.io"
              "45.90.30.163@853#${cfg.nextdnsProfileId}.dns.nextdns.io"
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
