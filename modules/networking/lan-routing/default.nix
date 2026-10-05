{
  config,
  pkgs,
  ...
}: let
  inherit (config.my.network.subnets) trusted;
  # Beats Tailscale's `5270 lookup 52`, where homeserver's advertised subnet would hairpin all LAN traffic through it.
  lanRule = "to ${trusted} lookup main priority 5200";
in {
  systemd.services.lan-route = {
    description = "Route trusted LAN traffic via main table, bypassing Tailscale subnet route";
    wantedBy = ["multi-user.target"];
    before = ["network-pre.target"];
    wants = ["network-pre.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "-${pkgs.iproute2}/bin/ip rule del ${lanRule}";
      ExecStart = "${pkgs.iproute2}/bin/ip rule add ${lanRule}";
      ExecStop = "${pkgs.iproute2}/bin/ip rule del ${lanRule}";
    };
  };
}
