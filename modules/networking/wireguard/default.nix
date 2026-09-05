{config, ...}: let
  # Transmission peer port, forwarded through the VPN namespace.
  vpnPort = 63998;
in {
  # SOPS secrets for WireGuard
  sops.secrets.wg_conf = {
    sopsFile = ../../../secrets/wg.conf;
    format = "binary";
    mode = "0600";
  };

  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = config.sops.secrets.wg_conf.path;

    # Make VPN namespace accessible from local network
    accessibleFrom =
      config.my.network.subnets.lan
      ++ [
        "10.0.0.0/8"
        "127.0.0.1/32"
      ];

    # Port forwarding from host to VPN namespace
    portMappings = [
      {
        from = vpnPort;
        to = vpnPort;
        protocol = "both";
      }
    ];

    # Open ports through the VPN interface
    openVPNPorts = [
      {
        port = vpnPort;
        protocol = "both";
      }
    ];
  };

  # Firewall rules to allow access to forwarded port
  networking.firewall = {
    allowedTCPPorts = [vpnPort];
    allowedUDPPorts = [vpnPort];
  };
}
