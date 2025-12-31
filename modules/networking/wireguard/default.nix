{
  config,
  pkgs,
  ...
}: {
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

  # Setup WireGuard in namespace
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
      '';

      ExecStop = pkgs.writeShellScript "wg-down" ''
        ${pkgs.iproute2}/bin/ip netns exec wg ${pkgs.iproute2}/bin/ip link del wg0 || true
      '';
    };
  };
}
