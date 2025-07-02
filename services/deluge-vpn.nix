{ config, pkgs, ... }:

{
  sops.secrets.wireguard_deluge = { };

  # Create WireGuard network namespace
  systemd.services.wireguard-wg-deluge = {
    description = "WireGuard tunnel for Deluge (wg-deluge)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Create network namespace
      ${pkgs.iproute2}/bin/ip netns add wg-deluge || true
      
      # Create WireGuard interface in namespace
      ${pkgs.iproute2}/bin/ip link add wg-deluge type wireguard
      ${pkgs.iproute2}/bin/ip link set wg-deluge netns wg-deluge
      
      # Configure WireGuard
      ${pkgs.iproute2}/bin/ip netns exec wg-deluge ${pkgs.wireguard-tools}/bin/wg setconf wg-deluge ${config.sops.secrets.wireguard_deluge.path}
      
      # Bring up interface
      ${pkgs.iproute2}/bin/ip netns exec wg-deluge ip link set wg-deluge up
      ${pkgs.iproute2}/bin/ip netns exec wg-deluge ip link set lo up
    '';

    preStop = ''
      ${pkgs.iproute2}/bin/ip netns delete wg-deluge || true
    '';
  };

  # Configure Deluge daemon in network namespace
  services.deluge = {
    enable = true;
    web.enable = true;
    web.port = 8112;
    
    # Use declarative configuration
    declarative = true;
    config = {
      download_location = "/home/zeev/downloads";
      listen_ports = [ 58846 58896 ];
      random_port = false;
    };
  };

  # Override deluge daemon to run in network namespace
  systemd.services.deluged = {
    after = [ "wireguard-wg-deluge.service" ];
    requires = [ "wireguard-wg-deluge.service" ];
    
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/wg-deluge";
    };
  };

  # Override deluge web to run in network namespace
  systemd.services.deluge-web = {
    after = [ "deluged.service" "wireguard-wg-deluge.service" ];
    requires = [ "deluged.service" "wireguard-wg-deluge.service" ];
    
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/wg-deluge";
    };
  };

  # Create downloads directory
  systemd.tmpfiles.rules = [
    "d /home/zeev/downloads 0755 zeev users -"
  ];

  # Open firewall for Deluge web interface
  networking.firewall.allowedTCPPorts = [ 8112 ];
}