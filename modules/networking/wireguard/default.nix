{config, ...}: let
  # qBittorrent peer port: AirVPN static forward into the tunnel; no host-side mapping (replies leave via the VPN anyway).
  vpnPort = 63998;
in {
  sops.secrets.wg_conf = {
    sopsFile = ../../../secrets/wg.conf;
    format = "binary";
    mode = "0600";
  };

  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = config.sops.secrets.wg_conf.path;

    accessibleFrom =
      config.my.network.subnets.lan
      ++ [
        "10.0.0.0/8"
        "127.0.0.1/32"
      ];

    openVPNPorts = [
      {
        port = vpnPort;
        protocol = "both";
      }
    ];
  };
}
