{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.wireguard;
in {
  options.my.wireguard = {
    enable = mkEnableOption "WireGuard VPN using VPN-Confinement (via nixarr)";

    forwardedPort = mkOption {
      type = types.nullOr types.port;
      default = null;
      description = "Port forwarded by VPN provider for incoming connections";
      example = 63998;
    };
  };

  config = mkIf cfg.enable {
    # SOPS secrets for WireGuard
    sops.secrets.wg_conf = {
      sopsFile = ../../../secrets/wg.conf;
      format = "binary";
      mode = "0600";
    };

    # VPN namespace configuration using VPN-Confinement
    # (nixarr reexports this module)
    vpnNamespaces.wg = {
      enable = true;
      wireguardConfigFile = config.sops.secrets.wg_conf.path;

      # Make VPN namespace accessible from local network
      accessibleFrom = [
        "192.168.0.0/24"
        "10.0.0.0/8"
        "127.0.0.1/32"
      ];

      # Port forwarding from host to VPN namespace (if configured)
      portMappings = mkIf (cfg.forwardedPort != null) [
        {
          from = cfg.forwardedPort;
          to = cfg.forwardedPort;
          protocol = "both";
        }
      ];

      # Open ports through the VPN interface (if configured)
      openVPNPorts = mkIf (cfg.forwardedPort != null) [
        {
          port = cfg.forwardedPort;
          protocol = "both";
        }
      ];
    };

    # Firewall rules to allow access to forwarded port (if configured)
    networking.firewall = mkIf (cfg.forwardedPort != null) {
      allowedTCPPorts = [cfg.forwardedPort];
      allowedUDPPorts = [cfg.forwardedPort];
    };
  };
}
