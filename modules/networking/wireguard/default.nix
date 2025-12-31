{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.my.wireguard;
in {
  options.my.wireguard = {
    enable = mkEnableOption "WireGuard VPN with network namespace";

    forwardedPort = mkOption {
      type = types.nullOr types.port;
      default = null;
      description = "Port forwarded by VPN provider for incoming connections";
      example = 51820;
    };
  };

  config = mkIf cfg.enable {
    # SOPS secrets for WireGuard
    sops.secrets = {
      wg_conf = {
        sopsFile = ../../../secrets/wg.conf;
        format = "binary";
        mode = "0600";
      };
    };

    # Install required packages
    environment.systemPackages = with pkgs; [
      wireguard-tools
      iproute2
    ];

    # Firewall rules for port forwarding
    networking.firewall = mkIf (cfg.forwardedPort != null) {
      allowedTCPPorts = [cfg.forwardedPort];
      allowedUDPPorts = [cfg.forwardedPort];
    };

    # NAT to forward traffic from root namespace to VPN namespace
    networking.nat = mkIf (cfg.forwardedPort != null) {
      enable = true;
      internalInterfaces = ["veth-wg"];
    };

    # Create network namespace
    systemd.services."netns@" = {
      description = "%I network namespace";
      before = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
        ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
      };
    };

    # Setup WireGuard in namespace with optional veth pair for port forwarding
    systemd.services.wg = {
      description = "WireGuard VPN in network namespace";
      after = ["netns@wg.service"];
      requires = ["netns@wg.service"];
      wantedBy = ["multi-user.target"];

      path = with pkgs; [
        iproute2
        wireguard-tools
        procps
        gnugrep
        iptables
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = pkgs.writeShellScript "wg-up" ''
          set -e

          # Move WireGuard interface to namespace
          ${pkgs.iproute2}/bin/ip link add wg0 type wireguard
          ${pkgs.iproute2}/bin/ip link set wg0 netns wg

          # Configure WireGuard in namespace
          ${pkgs.iproute2}/bin/ip netns exec wg ${pkgs.wireguard-tools}/bin/wg setconf wg0 ${config.sops.secrets.wg_conf.path}

          # Extract IP from config and set it
          ADDR=$(grep -E '^Address' ${config.sops.secrets.wg_conf.path} | head -n1 | cut -d'=' -f2 | tr -d ' ')
          ${pkgs.iproute2}/bin/ip netns exec wg ${pkgs.iproute2}/bin/ip addr add ''${ADDR} dev wg0

          # Bring up interface
          ${pkgs.iproute2}/bin/ip netns exec wg ${pkgs.iproute2}/bin/ip link set wg0 up
          ${pkgs.iproute2}/bin/ip netns exec wg ${pkgs.iproute2}/bin/ip link set lo up

          # Set default route through VPN
          ${pkgs.iproute2}/bin/ip netns exec wg ${pkgs.iproute2}/bin/ip route add default dev wg0

          ${optionalString (cfg.forwardedPort != null) ''
            # Create veth pair for port forwarding
            ${pkgs.iproute2}/bin/ip link add veth-wg type veth peer name veth-ns
            ${pkgs.iproute2}/bin/ip link set veth-ns netns wg

            # Configure root side
            ${pkgs.iproute2}/bin/ip addr add 10.200.200.1/24 dev veth-wg
            ${pkgs.iproute2}/bin/ip link set veth-wg up

            # Configure namespace side
            ${pkgs.iproute2}/bin/ip netns exec wg ${pkgs.iproute2}/bin/ip addr add 10.200.200.2/24 dev veth-ns
            ${pkgs.iproute2}/bin/ip netns exec wg ${pkgs.iproute2}/bin/ip link set veth-ns up

            # Add route in namespace to reach root namespace
            ${pkgs.iproute2}/bin/ip netns exec wg ${pkgs.iproute2}/bin/ip route add 10.200.200.0/24 dev veth-ns

            # Port forwarding rules
            ${pkgs.iptables}/bin/iptables -t nat -A PREROUTING -p tcp --dport ${toString cfg.forwardedPort} -j DNAT --to-destination 10.200.200.2:${toString cfg.forwardedPort}
            ${pkgs.iptables}/bin/iptables -t nat -A PREROUTING -p udp --dport ${toString cfg.forwardedPort} -j DNAT --to-destination 10.200.200.2:${toString cfg.forwardedPort}
            ${pkgs.iptables}/bin/iptables -A FORWARD -p tcp -d 10.200.200.2 --dport ${toString cfg.forwardedPort} -j ACCEPT
            ${pkgs.iptables}/bin/iptables -A FORWARD -p udp -d 10.200.200.2 --dport ${toString cfg.forwardedPort} -j ACCEPT
          ''}
        '';

        ExecStop = pkgs.writeShellScript "wg-down" ''
          ${optionalString (cfg.forwardedPort != null) ''
            # Clean up iptables rules
            ${pkgs.iptables}/bin/iptables -t nat -D PREROUTING -p tcp --dport ${toString cfg.forwardedPort} -j DNAT --to-destination 10.200.200.2:${toString cfg.forwardedPort} 2>/dev/null || true
            ${pkgs.iptables}/bin/iptables -t nat -D PREROUTING -p udp --dport ${toString cfg.forwardedPort} -j DNAT --to-destination 10.200.200.2:${toString cfg.forwardedPort} 2>/dev/null || true
            ${pkgs.iptables}/bin/iptables -D FORWARD -p tcp -d 10.200.200.2 --dport ${toString cfg.forwardedPort} -j ACCEPT 2>/dev/null || true
            ${pkgs.iptables}/bin/iptables -D FORWARD -p udp -d 10.200.200.2 --dport ${toString cfg.forwardedPort} -j ACCEPT 2>/dev/null || true

            # Remove veth pair
            ${pkgs.iproute2}/bin/ip link del veth-wg 2>/dev/null || true
          ''}

          ${pkgs.iproute2}/bin/ip netns exec wg ${pkgs.iproute2}/bin/ip link del wg0 || true
        '';
      };
    };
  };
}
