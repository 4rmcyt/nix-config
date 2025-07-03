{ config, pkgs, lib, ... }:

{
  sops.secrets.pia_username = {
    owner = "deluge";
    group = "deluge";
    mode = "0600";
  };

  sops.secrets.pia_password = {
    owner = "deluge";
    group = "deluge";
    mode = "0600";
  };

  # PIA WireGuard auto-configuration service
  systemd.services.pia-wg-setup = {
    description = "Setup PIA WireGuard configuration";
    wantedBy = [ "multi-user.target" ];
    before = [ "wireguard-wg-deluge.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "deluge";
      Group = "deluge";
    };
    
    script = ''
      # PIA WireGuard setup script
      PIA_USER=$(cat ${config.sops.secrets.pia_username.path})
      PIA_PASS=$(cat ${config.sops.secrets.pia_password.path})
      
      # Create working directory
      mkdir -p /var/lib/deluge/pia
      cd /var/lib/deluge/pia
      
      # Get auth token
      echo "Getting PIA auth token..."
      TOKEN=$(${pkgs.curl}/bin/curl -s -u "$PIA_USER:$PIA_PASS" \
        "https://www.privateinternetaccess.com/api/client/v2/token" | \
        ${pkgs.jq}/bin/jq -r '.token // empty')
      
      if [ -z "$TOKEN" ]; then
        echo "Failed to get auth token"
        exit 1
      fi
      
      # Get server list and select best server
      echo "Getting server list..."
      SERVER_LIST=$(${pkgs.curl}/bin/curl -s \
        "https://serverlist.piaservers.net/vpninfo/servers/v6")
      
      # Select a server (you can modify this to select specific region)
      SERVER_INFO=$(echo "$SERVER_LIST" | ${pkgs.jq}/bin/jq -r \
        '.regions[] | select(.geo == false) | select(.offline == false) | 
         select(.servers.wg != null) | .servers.wg[0]' | head -1)
      
      if [ -z "$SERVER_INFO" ]; then
        echo "No suitable WireGuard server found"
        exit 1
      fi
      
      SERVER_IP=$(echo "$SERVER_INFO" | ${pkgs.jq}/bin/jq -r '.ip')
      SERVER_PORT=$(echo "$SERVER_INFO" | ${pkgs.jq}/bin/jq -r '.port')
      
      # Generate WireGuard keypair
      PRIVATE_KEY=$(${pkgs.wireguard-tools}/bin/wg genkey)
      PUBLIC_KEY=$(echo "$PRIVATE_KEY" | ${pkgs.wireguard-tools}/bin/wg pubkey)
      
      # Get WireGuard configuration from PIA
      echo "Getting WireGuard configuration..."
      WG_CONFIG=$(${pkgs.curl}/bin/curl -s -G \
        --data-urlencode "pubkey=$PUBLIC_KEY" \
        --data-urlencode "token=$TOKEN" \
        "https://www.privateinternetaccess.com/api/client/v2/addkey")
      
      # Extract configuration
      PEER_KEY=$(echo "$WG_CONFIG" | ${pkgs.jq}/bin/jq -r '.peer_pubkey // empty')
      SERVER_KEY=$(echo "$WG_CONFIG" | ${pkgs.jq}/bin/jq -r '.server_key // empty')
      CLIENT_IP=$(echo "$WG_CONFIG" | ${pkgs.jq}/bin/jq -r '.peer_ip // empty')
      
      if [ -z "$PEER_KEY" ] || [ -z "$CLIENT_IP" ]; then
        echo "Failed to get WireGuard configuration"
        exit 1
      fi
      
      # Write configuration files
      echo "$PRIVATE_KEY" > /var/lib/deluge/pia/private_key
      echo "$PEER_KEY" > /var/lib/deluge/pia/peer_key
      echo "$CLIENT_IP" > /var/lib/deluge/pia/client_ip
      echo "$SERVER_IP:$SERVER_PORT" > /var/lib/deluge/pia/endpoint
      
      # Set permissions
      chmod 600 /var/lib/deluge/pia/*
      chown deluge:deluge /var/lib/deluge/pia/*
      
      echo "PIA WireGuard configuration complete"
      echo "Client IP: $CLIENT_IP"
      echo "Server: $SERVER_IP:$SERVER_PORT"
    '';
  };

  # WireGuard interface (networkd compatible)
  networking.wireguard.interfaces.wg-deluge = {
    privateKeyFile = "/var/lib/deluge/pia/private_key";
    # No postSetup/preShutdown - handle routing separately
  };

  # Separate service for VPN routing setup
  systemd.services.deluge-vpn-routing = {
    description = "Setup VPN routing for Deluge";
    wantedBy = [ "multi-user.target" ];
    after = [ "wireguard-wg-deluge.service" "pia-wg-setup.service" ];
    wants = [ "wireguard-wg-deluge.service" "pia-wg-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      # Wait for PIA setup to complete
      while [ ! -f /var/lib/deluge/pia/client_ip ]; do
        sleep 1
      done
      
      # Read configuration
      CLIENT_IP=$(cat /var/lib/deluge/pia/client_ip)
      PEER_KEY=$(cat /var/lib/deluge/pia/peer_key)
      ENDPOINT=$(cat /var/lib/deluge/pia/endpoint)
      
      # Configure interface
      ${pkgs.iproute2}/bin/ip addr add $CLIENT_IP/32 dev wg-deluge || true
      
      # Add peer
      ${pkgs.wireguard-tools}/bin/wg set wg-deluge peer $PEER_KEY \
        allowed-ips 0.0.0.0/0 \
        endpoint $ENDPOINT \
        persistent-keepalive 25
      
      # Setup routing table
      ${pkgs.iproute2}/bin/ip route add default dev wg-deluge table 42 || true
      
      # Add routing rules for deluge user
      ${pkgs.iproute2}/bin/ip rule add uidrange 993-993 table 42 || true
      ${pkgs.iproute2}/bin/ip rule add uidrange 993-993 unreachable || true
      
      # Flush route cache
      ${pkgs.iproute2}/bin/ip route flush cache
    '';
    
    preStop = ''
      ${pkgs.iproute2}/bin/ip rule del uidrange 993-993 table 42 || true
      ${pkgs.iproute2}/bin/ip rule del uidrange 993-993 unreachable || true
      ${pkgs.iproute2}/bin/ip route flush table 42 || true
    '';
  };

  # Deluge service
  services.deluge = {
    enable = true;
    web = {
      enable = true;
      port = 8112;
    };
    
    authFile = pkgs.writeText "deluge-auth" "admin:admin:10";
    
    declarative = true;
    config = {
      listen_interface = "0.0.0.0";
      listen_ports = [ 58846 58847 ];
      download_location = "/home/zeev/downloads";
      torrentfiles_location = "/var/lib/deluge/torrents";
      max_connections_global = 200;
      max_upload_speed = 1000.0;
      max_download_speed = -1.0;
      allow_remote = true;
      daemon_port = 58846;
      upnp = false;
      natpmp = false;
    };
  };

  # Service dependencies
  systemd.services.deluged = {
    after = [ "deluge-vpn-routing.service" ];
    wants = [ "deluge-vpn-routing.service" ];
    serviceConfig = {
      User = "deluge";
      Group = "deluge";
    };
  };

  # VPN kill switch
  systemd.services.deluge-kill-switch = {
    description = "Deluge VPN kill switch";
    after = [ "deluged.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Block all traffic except VPN for deluge user
      ${pkgs.iptables}/bin/iptables -A OUTPUT -m owner --uid-owner deluge -o wg-deluge -j ACCEPT
      ${pkgs.iptables}/bin/iptables -A OUTPUT -m owner --uid-owner deluge -o lo -j ACCEPT
      ${pkgs.iptables}/bin/iptables -A OUTPUT -m owner --uid-owner deluge -j DROP
    '';
    preStop = ''
      ${pkgs.iptables}/bin/iptables -D OUTPUT -m owner --uid-owner deluge -o wg-deluge -j ACCEPT || true
      ${pkgs.iptables}/bin/iptables -D OUTPUT -m owner --uid-owner deluge -o lo -j ACCEPT || true
      ${pkgs.iptables}/bin/iptables -D OUTPUT -m owner --uid-owner deluge -j DROP || true
    '';
  };

  # Directory setup
  systemd.tmpfiles.rules = [
    "d /var/lib/deluge 0755 deluge deluge -"
    "d /var/lib/deluge/pia 0755 deluge deluge -"
    "d /var/lib/deluge/torrents 0755 deluge deluge -"
    "d /home/zeev/downloads 0755 zeev users -"
  ];

  # Firewall
  networking.firewall.allowedTCPPorts = [ 8112 ];

  # Routing table
  networking.iproute2 = {
    enable = true;
    rttablesExtraConfig = "42 deluge-vpn";
  };

  # System settings
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 2;
  };
}