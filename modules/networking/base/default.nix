{
  config,
  pkgs,
  lib,
  ...
}:

{
  networking = {
    hostName = "homeserver";
    hostId = "0b8d0f5a";
    networkmanager.enable = true;
    useDHCP = lib.mkForce true;
    enableIPv6 = false;

    firewall = {
      enable = true;

      # Logging
      logReversePathDrops = true;
      logRefusedConnections = false; # Avoid log spam

      extraCommands = ''
        # Drop invalid packets
        iptables -A nixos-fw -m conntrack --ctstate INVALID -j DROP

        # Rate limit SSH
        iptables -A nixos-fw -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name SSH
        iptables -A nixos-fw -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP

        # Block common attack vectors
        iptables -A nixos-fw -p tcp --tcp-flags ALL NONE -j DROP
        iptables -A nixos-fw -p tcp --tcp-flags ALL ALL -j DROP
        iptables -A nixos-fw -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
        iptables -A nixos-fw -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

        # Geo-blocking (example for known bad actors)
        # iptables -A nixos-fw -m geoip --src-cc CN,RU,KP -j DROP
      '';

      allowedTCPPorts = [
        # Base services
        22 # SSH
        80 # HTTP
        443 # HTTPS

        # 11434 # Ollama API
        # 11435 # Ollama WebUI

        # Monitoring (from monitoring.nix)
        3000 # Grafana
        9090 # Prometheus
        9100 # Node Exporter
        # 8000  # TP-Link Exporter
        # 9948  # Nextdns Exporter
        27196 # Cloudflare Exporter
        3001 # Uptime Kuma

        # Database & Infrastructure
        5432 # PostgreSQL (if needed externally)
        9091

      ];

      # rejectPackets = true;

      # # Rate limiting for SSH
      # extraCommands = ''
      #   # Rate limit SSH connections
      #   iptables -A nixos-fw -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name SSH
      #   iptables -A nixos-fw -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP

      #   # Block common attack ports
      #   iptables -A nixos-fw -p tcp --dport 23 -j DROP  # Telnet
      #   iptables -A nixos-fw -p tcp --dport 135 -j DROP # RPC
      #   iptables -A nixos-fw -p tcp --dport 445 -j DROP # SMB
      # '';

      # kernel.sysctl = {
      #   # IP Spoofing protection
      #   "net.ipv4.conf.default.rp_filter" = 1;
      #   "net.ipv4.conf.all.rp_filter" = 1;

      #   # IP redirects
      #   "net.ipv4.conf.all.accept_redirects" = 0;
      #   "net.ipv6.conf.all.accept_redirects" = 0;
      #   "net.ipv4.conf.all.send_redirects" = 0;

      #   # Source packet routing
      #   "net.ipv4.conf.all.accept_source_route" = 0;
      #   "net.ipv6.conf.all.accept_source_route" = 0;

      #   # Log Martians
      #   "net.ipv4.conf.all.log_martians" = 1;

      #   # ICMP
      #   "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      #   "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

      #   # TCP hardening
      #   "net.ipv4.tcp_syncookies" = 1;
      #   "net.ipv4.tcp_rfc1337" = 1;
      # };

      trustedInterfaces = [ "tailscale0" ];
    };
  };
}
