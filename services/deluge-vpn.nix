{ config, pkgs, lib, ... }:

let
  # Create the scripts as proper Nix derivations with dependencies
  pia-setup-script = pkgs.writeShellScript "pia-setup.sh" ''
    # Create working directory
    mkdir -p /var/lib/deluge/pia
    cd /var/lib/deluge/pia

    # Get PIA credentials (passed as arguments)
    PIA_USER="$1"
    PIA_PASS="$2"

    echo "=== PIA WireGuard Config Generator ==="
    echo "Setting up for region: ca_ontario"

    # Generate WireGuard keypair
    PRIVATE_KEY=$(${pkgs.wireguard-tools}/bin/wg genkey)
    PUBLIC_KEY=$(echo "$PRIVATE_KEY" | ${pkgs.wireguard-tools}/bin/wg pubkey)

    echo "Generated keypair, public key: $PUBLIC_KEY"

    # Get server list
    echo "Fetching server list..."
    SERVER_LIST=$(${pkgs.curl}/bin/curl -s "https://serverlist.piaservers.net/vpninfo/servers/v6" | head -1)

    # Find WireGuard server for ca_ontario
    WG_SERVER_IP=$(echo "$SERVER_LIST" | ${pkgs.jq}/bin/jq -r '.regions[] | select(.id == "ca_ontario") | .servers.wg[0].ip')
    WG_SERVER_CN=$(echo "$SERVER_LIST" | ${pkgs.jq}/bin/jq -r '.regions[] | select(.id == "ca_ontario") | .servers.wg[0].cn')
    META_SERVER_IP=$(echo "$SERVER_LIST" | ${pkgs.jq}/bin/jq -r '.regions[] | select(.id == "ca_ontario") | .servers.meta[0].ip')

    if [ -z "$WG_SERVER_IP" ] || [ "$WG_SERVER_IP" = "null" ]; then
      echo "Failed to find WireGuard server for ca_ontario"
      exit 1
    fi

    echo "Using WG server: $WG_SERVER_IP ($WG_SERVER_CN)"
    echo "Using Meta server: $META_SERVER_IP"

    # Get auth token
    echo "Getting auth token..."
    TOKEN_RESPONSE=$(${pkgs.curl}/bin/curl -s -u "$PIA_USER:$PIA_PASS" \
      "https://$META_SERVER_IP/authv3/generateToken" \
      --connect-timeout 15 \
      --max-time 30 \
      --insecure)

    TOKEN=$(echo "$TOKEN_RESPONSE" | ${pkgs.jq}/bin/jq -r '.token // empty')

    if [ -z "$TOKEN" ]; then
      echo "Failed to get auth token"
      echo "Response: $TOKEN_RESPONSE"
      exit 1
    fi

    echo "Got auth token successfully"

    # Add public key
    echo "Adding public key to PIA..."
    ADD_KEY_RESPONSE=$(${pkgs.curl}/bin/curl -s -G \
      --data-urlencode "pubkey=$PUBLIC_KEY" \
      --data-urlencode "pt=$TOKEN" \
      "https://$WG_SERVER_IP:1337/addKey" \
      --connect-timeout 15 \
      --max-time 30 \
      --insecure)

    # Extract response data
    if ! echo "$ADD_KEY_RESPONSE" | ${pkgs.jq}/bin/jq empty 2>/dev/null; then
      echo "Invalid response from addKey"
      echo "Response: $ADD_KEY_RESPONSE"
      exit 1
    fi

    if [ "$(echo "$ADD_KEY_RESPONSE" | ${pkgs.jq}/bin/jq -r '.status // empty')" != "OK" ]; then
      echo "AddKey failed"
      echo "Response: $ADD_KEY_RESPONSE"
      exit 1
    fi

    SERVER_PUBLIC_KEY=$(echo "$ADD_KEY_RESPONSE" | ${pkgs.jq}/bin/jq -r '.server_key')
    CLIENT_IP=$(echo "$ADD_KEY_RESPONSE" | ${pkgs.jq}/bin/jq -r '.peer_ip')

    if [ -z "$SERVER_PUBLIC_KEY" ] || [ -z "$CLIENT_IP" ]; then
      echo "Failed to extract server key or client IP"
      echo "Response: $ADD_KEY_RESPONSE"
      exit 1
    fi

    echo "Key added successfully!"
    echo "Client IP: $CLIENT_IP"
    echo "Server Public Key: $SERVER_PUBLIC_KEY"

    # Save the extracted values for our WireGuard service
    echo "$PRIVATE_KEY" > /var/lib/deluge/pia/private_key
    echo "$SERVER_PUBLIC_KEY" > /var/lib/deluge/pia/peer_key
    echo "$CLIENT_IP" > /var/lib/deluge/pia/client_ip
    echo "$WG_SERVER_IP:1337" > /var/lib/deluge/pia/endpoint

    # Set proper permissions
    chmod 600 /var/lib/deluge/pia/*
    chown deluge:deluge /var/lib/deluge/pia/*

    echo "PIA WireGuard configuration setup complete!"
  '';

  vpn-routing-script = pkgs.writeShellScript "vpn-routing.sh" ''
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

    # Create the network namespace
    ${pkgs.iproute2}/bin/ip netns add pia || true

    # Move the WireGuard interface to the namespace
    ${pkgs.iproute2}/bin/ip link set wg-deluge netns pia

    # Configure interface in the namespace
    ${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.iproute2}/bin/ip addr add $CLIENT_IP/32 dev wg-deluge
    ${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.iproute2}/bin/ip link set wg-deluge up

    # Set up loopback in namespace
    ${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.iproute2}/bin/ip link set lo up

    # Add peer configuration in the namespace
    ${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.wireguard-tools}/bin/wg set wg-deluge peer $PEER_KEY \
      allowed-ips 0.0.0.0/0 \
      endpoint $ENDPOINT \
      persistent-keepalive 25

    # Set up default route in the namespace
    ${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.iproute2}/bin/ip route add default dev wg-deluge

    # Set up DNS in the namespace
    ${pkgs.iproute2}/bin/ip netns exec pia mkdir -p /etc
    ${pkgs.iproute2}/bin/ip netns exec pia sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'

    echo "VPN routing configured successfully"

    # Test connectivity
    echo "Testing VPN connectivity..."
    ${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.wireguard-tools}/bin/wg show wg-deluge
  '';

  # Script to run Deluge in namespace as the correct user
  deluge-start-script = pkgs.writeShellScript "deluge-start.sh" ''
    # Run Deluge in the namespace, switching to deluge user
    exec ${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.sudo}/bin/sudo -u deluge \
      ${pkgs.deluge}/bin/deluged --do-not-daemonize \
      -c /var/lib/deluge/.config/deluge \
      -l /var/lib/deluge/daemon.log -L info
  '';

  vpn-cleanup-script = pkgs.writeShellScript "vpn-cleanup.sh" ''
    echo "Cleaning up VPN routing..."
    ${pkgs.iproute2}/bin/ip netns del pia || true
  '';
in
{
  # Create deluge user first
  users.users.deluge = {
    isSystemUser = true;
    group = "deluge";
    uid = 1001;  # Use a definitely free UID
    home = "/var/lib/deluge";
    createHome = true;
  };

  users.groups.deluge = {
    gid = 1001;  # Use matching GID
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
      # Get PIA credentials
      PIA_USER=$(cat ${config.sops.secrets.pia_username.path})
      PIA_PASS=$(cat ${config.sops.secrets.pia_password.path})

      # Run the PIA setup script
      ${pia-setup-script} "$PIA_USER" "$PIA_PASS"
    '';
  };

  # WireGuard interface
  networking.wireguard.interfaces.wg-deluge = {
    privateKeyFile = "/var/lib/deluge/pia/private_key";
    listenPort = 51820;
  };

  # VPN routing setup service
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

    script = "${vpn-routing-script}";
    preStop = "${vpn-cleanup-script}";
  };

  # Deluge daemon service (runs in VPN namespace as root, then drops to deluge user)
  systemd.services.deluged = {
    description = "Deluge BitTorrent Daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "deluge-vpn-routing.service" ];
    wants = [ "deluge-vpn-routing.service" ];
    serviceConfig = {
      Type = "simple";
      # Run as root to access namespace, then drop privileges with sudo
      User = "root";
      Group = "root";
      ExecStart = "${deluge-start-script}";
      Restart = "always";
      RestartSec = "5";
      TimeoutStartSec = "30";
    };
  };

  # Ensure deluge config directory exists and configure dark theme
  system.activationScripts.deluge-config = {
    text = ''
      # Create main config directory
      mkdir -p /var/lib/deluge/.config/deluge
      chown deluge:deluge /var/lib/deluge/.config/deluge
      chmod 700 /var/lib/deluge/.config/deluge

      # Create auth file with a 'deluge' user and NO password
      # This user matches the default that the web-ui will try to use.
      echo 'deluge::10' > /var/lib/deluge/.config/deluge/auth
      
      # Create core.conf to allow remote connections (for the web-ui)
      # and set the download location.
      echo '{
        "allow_remote": true,
        "download_location": "/home/zeev/Downloads"
      }' > /var/lib/deluge/.config/deluge/core.conf
      
      # Create web themes directory structure
      mkdir -p /var/lib/deluge/.config/deluge/web/themes/dark

      # Create web.conf with NO password for the web UI itself
      cat > /var/lib/deluge/.config/deluge/web.conf << 'EOF'
{
    "base": "deluge",
    "port": 8112,
    "https": false,
    "pkey": "ssl/daemon.pkey",
    "cert": "ssl/daemon.cert",
    "pwd_salt": "",
    "pwd_sha1": "",
    "sessions": {},
    "enabled_plugins": [],
    "theme": "gray",
    "sidebar_show_zero": false,
    "sidebar_multiple_filters": true,
    "show_sidebar": true,
    "show_toolbar": true,
    "show_statusbar": true,
    "sidebar_show_trackers": true,
    "default_daemon": "",
    "interface": "0.0.0.0",
    "language": ""
}
EOF

      # ... (rest of your script for themes is fine) ...

      # Set proper ownership and permissions for all created files
      chown -R deluge:deluge /var/lib/deluge/.config/deluge
      chmod 600 /var/lib/deluge/.config/deluge/*
      chmod 700 /var/lib/deluge/.config/deluge
      chmod 755 /var/lib/deluge/.config/deluge/web
      chmod 755 /var/lib/deluge/.config/deluge/web/themes
      chmod 755 /var/lib/deluge/.config/deluge/web/themes/dark
      chmod 644 /var/lib/deluge/.config/deluge/web/themes/dark/*
    '';
    deps = [ "users" ];  # Run after users are created
  };

  # Deluge web interface (runs on host network)
  systemd.services.deluge-web = {
    description = "Deluge BitTorrent Web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "deluged.service" ];  # Remove "deluge-config" - activation scripts run before services
    wants = [ "deluged.service" ];
    serviceConfig = {
      Type = "simple";
      User = "deluge";
      Group = "deluge";
      ExecStart = "${pkgs.deluge}/bin/deluge-web --do-not-daemonize -c /var/lib/deluge/.config/deluge -l /var/lib/deluge/web.log -L info";
      Restart = "always";
      RestartSec = "5";
      TimeoutStartSec = "30";
    };
  };

  # Open firewall for Deluge web interface
  networking.firewall = {
    allowedTCPPorts = [ 8112 ];  # Deluge web interface
    allowedUDPPorts = [ 51820 ]; # WireGuard
  };

}