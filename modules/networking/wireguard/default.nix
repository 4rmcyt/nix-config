{config, ...}: {
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
    accessibleFrom = [
      "192.168.0.0/24"
      "10.0.0.0/8"
      "127.0.0.1/32"
      "0.0.0.0/0"
    ];

    # Port forwarding from host to VPN namespace
    portMappings = [
      {
        from = 63998;
        to = 63998;
        protocol = "both";
      }
    ];

    # Open ports through the VPN interface
    openVPNPorts = [
      {
        port = 63998;
        protocol = "both";
      }
    ];
  };

  # Firewall rules to allow access to forwarded port
  networking.firewall = {
    allowedTCPPorts = [63998];
    allowedUDPPorts = [63998];
  };
}
