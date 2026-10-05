# Tailnet policy (default-deny grants); unlisted nodes (router, matebook, ua-exit as source) get nothing.
{config}: let
  inherit (config.my.network) hosts ports subnets;
  phones = ["s23plus" "s23ultra"];
in {
  hosts = {
    desktop = hosts.desktop_ts;
    homeserver = hosts.homeserver_ts;
    gcp-relay = hosts.gcp-relay_ts;
    s23plus = hosts.s23plus_ts;
    s23ultra = hosts.s23ultra_ts;
    lan = subnets.trusted;
  };

  grants = [
    {
      src = ["desktop"];
      dst = ["*" "autogroup:internet"];
      ip = ["*"];
    }
    {
      src = phones;
      dst = ["homeserver" "desktop" "lan" "autogroup:internet"];
      ip = ["*"];
    }
    {
      src = ["gcp-relay"];
      dst = ["homeserver"];
      ip = ["tcp:${toString ports.crowdsec-lapi}" "tcp:${toString ports.victorialogs}" "53"];
    }
    {
      src = ["homeserver"];
      dst = ["gcp-relay"];
      ip = ["tcp:${toString ports.node-exporter}"];
    }
    {
      src = ["homeserver"];
      dst = ["desktop"];
      ip = ["tcp:22"];
    }
    # Any device registered under the `guest` user: guest-only Caddy port + split DNS.
    {
      src = ["guest@"];
      dst = ["homeserver"];
      ip = ["tcp:${toString ports.caddy-guest}" "53"];
    }
  ];
}
