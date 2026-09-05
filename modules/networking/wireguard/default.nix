{config, ...}: let
  # Transmission peer port, forwarded through the VPN namespace.
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

    portMappings = [
      {
        from = vpnPort;
        to = vpnPort;
        protocol = "both";
      }
    ];

    openVPNPorts = [
      {
        port = vpnPort;
        protocol = "both";
      }
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [vpnPort];
    allowedUDPPorts = [vpnPort];
  };
}
