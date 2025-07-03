{ config, pkgs, lib, ... }:

{
  # Create deluge user first
  users.users.deluge = {
    isSystemUser = true;
    group = "deluge";
    uid = 993;
    home = "/var/lib/deluge";
    createHome = true;
  };

  users.groups.deluge = {
    gid = 993;
  };

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

  # Copy the PIA script content directly
  environment.etc."pia-wg.sh" = {
    text = builtins.readFile ../scripts/pia-wg.sh;
    mode = "0755";
  };

  # Service to generate PIA WireGuard config
  systemd.services.pia-wg-setup = {
    description = "Generate PIA WireGuard configuration";
    wantedBy = [ "multi-user.target" ];
    before = [ "wireguard-wg-deluge.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "120s";
    };

    script = ''
      # Create working directory
      mkdir -p /var/lib/deluge/pia
      cd /var/lib/deluge/pia

      # Get PIA credentials
      PIA_USER=$(cat ${config.sops.secrets.pia_username.path})
      PIA_PASS=$(cat ${config.sops.secrets.pia_password.path})

      # Create the pia-config.sh file that the script expects
      cat > /tmp/pia-config.sh << EOF
# Configuration for pia-wg.sh script
CONFIG="/tmp/pia.conf"
TOKENFILE="/tmp/token"
DATAFILE_NEW="/tmp/data-new.json"
PIA_CERT="/tmp/rsa_4096.crt"
CONNCACHE="/tmp/cache.json"
REMOTEINFO="/tmp/remote.json"
WGCONF="/tmp/wg.conf"

# Default settings
LOC="ca_ontario"
PIA_INTERFACE="pia"
CLIENT_PRIVATE_KEY=""
HARDWARE_ROUTE_TABLE="hardlinks"
VPNONLY_ROUTE_TABLE="vpnonly"

# Terminal formatting
BOLD=\$'\\e[1m'
NORMAL=\$'\\e[0m'
TAB=\$'\\t'
EOF

      # Set environment variables for the script
      export PIA_USERNAME="$PIA_USER"
      export PIA_PASSWORD="$PIA_PASS"
      export PIA_CONFIG="/tmp/pia-config.sh"

      # Make sure we have required packages in PATH
      export PATH="${pkgs.curl}/bin:${pkgs.jq}/bin:${pkgs.openssl}/bin:${pkgs.wireguard-tools}/bin:${pkgs.iproute2}/bin:$PATH"

      # Run the PIA script in config-only mode (-c flag)
      echo "Running PIA WireGuard script to generate config..."
      ${pkgs.bash}/bin/bash /etc/pia-wg.sh -c

      # Check if config was generated
      if [ ! -f "/tmp/wg.conf" ]; then
        echo "Failed to generate WireGuard config"
        echo "Contents of /tmp:"
        ls -la /tmp/
        exit 1
      fi

      echo "WireGuard config generated successfully:"
      cat /tmp/wg.conf

      # Extract values from the generated config
      PRIVATE_KEY=$(grep "PrivateKey" /tmp/wg.conf | cut -d'=' -f2 | xargs)
      CLIENT_IP=$(grep "Address" /tmp/wg.conf | cut -d'=' -f2 | xargs)
      PEER_KEY=$(grep "PublicKey" /tmp/wg.conf | cut -d'=' -f2 | xargs)
      ENDPOINT=$(grep "Endpoint" /tmp/wg.conf | cut -d'=' -f2 | xargs)

      # Validate extracted values
      if [ -z "$PRIVATE_KEY" ] || [ -z "$CLIENT_IP" ] || [ -z "$PEER_KEY" ] || [ -z "$ENDPOINT" ]; then
        echo "Failed to extract required values from WireGuard config"
        echo "Private Key: '$PRIVATE_KEY'"
        echo "Client IP: '$CLIENT_IP'"
        echo "Peer Key: '$PEER_KEY'"
        echo "Endpoint: '$ENDPOINT'"
        exit 1
      fi

      # Save the extracted values for our WireGuard service
      echo "$PRIVATE_KEY" > /var/lib/deluge/pia/private_key
      echo "$PEER_KEY" > /var/lib/deluge/pia/peer_key  
      echo "$CLIENT_IP" > /var/lib/deluge/pia/client_ip
      echo "$ENDPOINT" > /var/lib/deluge/pia/endpoint

      # Set proper permissions
      chmod 600 /var/lib/deluge/pia/*
      chown deluge:deluge /var/lib/deluge/pia/*

      echo "Extracted configuration:"
      echo "Private Key: $PRIVATE_KEY"
      echo "Client IP: $CLIENT_IP"
      echo "Peer Key: $PEER_KEY"
      echo "Endpoint: $ENDPOINT"

      # Also copy the full config for reference
      cp /tmp/wg.conf /var/lib/deluge/pia/wg.conf
      chown deluge:deluge /var/lib/deluge/pia/wg.conf

      echo "PIA WireGuard configuration setup complete!"
    '';
  };

  # WireGuard interface
  networking.wireguard.interfaces.wg-deluge = {
    privateKeyFile = "/var/lib/deluge/pia/private_key";
    listenPort = 51820;
    
    # Interface will be configured by the routing service
    # since we need to read the generated config files
  };

  # VPN routing setup with proper timeout
  systemd.services.deluge-vpn-routing = {
    description = "Setup VPN routing for Deluge";
    wantedBy = [ "multi-user.target" ];
    after = [ "wireguard-wg-deluge.service" "pia-wg-setup.service" ];
    wants = [ "wireguard-wg-deluge.service" "pia-wg-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "60s";
    };

    script = ''
      # Wait for PIA setup with timeout
      TIMEOUT=30
      COUNT=0
      while [ ! -f /var/lib/deluge/pia/client_ip ] && [ $COUNT -lt $TIMEOUT ]; do
        echo "Waiting for PIA setup... ($COUNT/$TIMEOUT)"
        sleep 2
        COUNT=$((COUNT + 1))
      done

      if [ ! -f /var/lib/deluge/pia/client_ip ]; then
        echo "PIA setup timeout - files not found"
        exit 1
      fi

      # Read configuration
      CLIENT_IP=$(cat /var/lib/deluge/pia/client_ip)
      PEER_KEY=$(cat /var/lib/deluge/pia/peer_key)
      ENDPOINT=$(cat /var/lib/deluge/pia/endpoint)

      echo "Setting up VPN routing for $CLIENT_IP"
      echo "Peer: $PEER_KEY"
      echo "Endpoint: $ENDPOINT"

      # Make sure interface is up
      ${pkgs.iproute2}/bin/ip link set wg-deluge up || true

      # Configure interface IP
      ${pkgs.iproute2}/bin/ip addr add $CLIENT_IP/32 dev wg-deluge || true

      # Add peer configuration
      ${pkgs.wireguard-tools}/bin/wg set wg-deluge peer $PEER_KEY \
        allowed-ips 0.0.0.0/0 \
        endpoint $ENDPOINT \
        persistent-keepalive 25

      # Setup routing table for deluge user (UID 993)
      ${pkgs.iproute2}/bin/ip route add default dev wg-deluge table 42 || true
      ${pkgs.iproute2}/bin/ip rule add uidrange 993-993 table 42 || true

      # Flush route cache
      ${pkgs.iproute2}/bin/ip route flush cache

      echo "VPN routing configured successfully"
      
      # Test connectivity
      echo "Testing VPN connectivity..."
      ${pkgs.wireguard-tools}/bin/wg show wg-deluge
      
      # Test if we can reach the internet through VPN
      echo "Testing internet connectivity through VPN..."
      if ${pkgs.iproute2}/bin/ip netns exec vpn-deluge ${pkgs.curl}/bin/curl -s --max-time 10 https://api.ipify.org 2>/dev/null; then
        echo "VPN connectivity test successful"
      else
        echo "VPN connectivity test failed (this might be normal if netns isn't set up yet)"
      fi
    '';

    preStop = ''
      echo "Cleaning up VPN routing..."
      ${pkgs.iproute2}/bin/ip rule del uidrange 993-993 table 42 || true
      ${pkgs.iproute2}/bin/ip route flush table 42 || true
      ${pkgs.wireguard-tools}/bin/wg set wg-deluge peer remove || true
    '';
  };

  # Deluge daemon service
  systemd.services.deluged = {
    description = "Deluge BitTorrent Daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "deluge-vpn-routing.service" ];
    wants = [ "deluge-vpn-routing.service" ];
    serviceConfig = {
      Type = "forking";
      User = "deluge";
      Group = "deluge";
      UMask = "0002";
      ExecStart = "${pkgs.deluge}/bin/deluged -d -c /var/lib/deluge/.config/deluge -l /var/lib/deluge/daemon.log -L info";
      PIDFile = "/var/lib/deluge/.config/deluge/deluged.pid";
      Restart = "on-failure";
      
      # Network namespace for VPN-only connectivity
      PrivateNetwork = false;  # We'll handle this with routing rules instead
    };
  };

  # Deluge web interface
  systemd.services.deluge-web = {
    description = "Deluge BitTorrent Web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "deluged.service" ];
    wants = [ "deluged.service" ];
    serviceConfig = {
      Type = "forking";
      User = "deluge";
      Group = "deluge";
      ExecStart = "${pkgs.deluge}/bin/deluge-web -d -c /var/lib/deluge/.config/deluge -l /var/lib/deluge/web.log -L info";
      PIDFile = "/var/lib/deluge/.config/deluge/deluge-web.pid";
      Restart = "on-failure";
    };
  };

  # Open firewall for Deluge web interface
  networking.firewall = {
    allowedTCPPorts = [ 8112 ];  # Deluge web interface
    allowedUDPPorts = [ 51820 ]; # WireGuard
  };

  # Ensure deluge config directory exists
  system.activationScripts.deluge-config = ''
    mkdir -p /var/lib/deluge/.config/deluge
    chown deluge:deluge /var/lib/deluge/.config/deluge
    chmod 755 /var/lib/deluge/.config/deluge
  '';
}