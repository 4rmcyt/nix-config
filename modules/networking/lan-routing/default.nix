{
  config,
  pkgs,
  ...
}: let
  inherit (config.my.network.subnets) trusted;
  # Replies to LAN-originated connections must leave via LAN, not the accepted Tailscale subnet route (table 52).
  replyRule = "from ${trusted} to ${trusted} lookup main priority 5205";
in {
  systemd.services.lan-reply-route = {
    description = "Route LAN-to-LAN replies via main table, bypassing Tailscale";
    wantedBy = ["multi-user.target"];
    before = ["network-pre.target"];
    wants = ["network-pre.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "-${pkgs.iproute2}/bin/ip rule del ${replyRule}";
      ExecStart = "${pkgs.iproute2}/bin/ip rule add ${replyRule}";
      ExecStop = "${pkgs.iproute2}/bin/ip rule del ${replyRule}";
    };
  };
}
