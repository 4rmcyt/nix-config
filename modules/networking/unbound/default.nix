{
  config,
  lib,
  ...
}: let
  cfg = config.my.unbound;
  inherit (config.my.defaults) domain gcpRelayIp nextdnsProfileId;
  inherit (config.my.network.hosts) homeserver_lan homeserver_ts;

  # "transparent" so redirect on the parent zone doesn't swallow MagicDNS lookups too.
  zones = homeserverIp: {
    local-zone = [
      ''"ts.${domain}." transparent''
      ''"${domain}." redirect''
      ''"hs.${domain}." static''
      ''"hp.${domain}." static''
    ];
    local-data = [
      ''"${domain}. A ${homeserverIp}"''
      ''"hs.${domain}. A ${gcpRelayIp}"''
      ''"hp.${domain}. A ${gcpRelayIp}"''
    ];
  };
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
      after = ["tailscale.service" "tailscale-autoconnect.service" "sys-subsystem-net-devices-tailscale0.device"];
      wants = ["tailscale.service" "sys-subsystem-net-devices-tailscale0.device"];
      serviceConfig.Restart = "on-failure";
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

          # ts.domain is a private zone with no real DNSSEC signature — would SERVFAIL otherwise.
          domain-insecure = ["${domain}"];

          # Tailnet clients (MagicDNS split DNS) get only homeserver_ts; others get homeserver_lan.
          access-control-view = ["${config.my.network.subnets.tailscale} tailnet"];

          inherit (zones homeserver_lan) local-zone local-data;
        };

        # View zones replace the global ones entirely, so hs/hp/ts carve-outs are repeated via zones.
        view = [
          ({name = "tailnet";} // zones homeserver_ts)
        ];

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
