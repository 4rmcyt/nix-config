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
      chmod 755 /var/lib/deluge/.config/deluge

      # Create web themes directory structure
      mkdir -p /var/lib/deluge/.config/deluge/web/themes/dark
      
      # Create web.conf with dark theme configuration
      cat > /var/lib/deluge/.config/deluge/web.conf << 'EOF'
{
    "base": "deluge",
    "port": 8112,
    "https": false,
    "pkey": "ssl/daemon.pkey", 
    "cert": "ssl/daemon.cert",
    "pwd_salt": "c26ab3bbd8b137f99cd83c2c1c0963bcc1a35cad",
    "pwd_sha1": "2ce1a410bcdcc53064129b6d950bda9458e4292f",
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

      # Create dark theme CSS file
      cat > /var/lib/deluge/.config/deluge/web/themes/dark/style.css << 'EOF'
/* Dark theme for Deluge Web UI */
body, .x-panel-body, .x-window-body {
    background-color: #2b2b2b !important;
    color: #ffffff !important;
}

.x-panel, .x-window, .x-grid-panel, .x-form-panel {
    background-color: #3c3c3c !important;
    color: #ffffff !important;
    border-color: #555555 !important;
}

.x-toolbar, .x-toolbar-left-row, .x-toolbar-right-row {
    background-color: #404040 !important;
    background-image: none !important;
    border-color: #555555 !important;
}

.x-grid3-header {
    background-color: #404040 !important;
    background-image: none !important;
    border-color: #555555 !important;
}

.x-grid3-header-inner, .x-grid3-hd-inner {
    color: #ffffff !important;
}

.x-grid3-row {
    background-color: #3c3c3c !important;
    color: #ffffff !important;
    border-color: #555555 !important;
}

.x-grid3-row-alt {
    background-color: #454545 !important;
}

.x-grid3-row-over {
    background-color: #5a5a5a !important;
}

.x-grid3-row-selected {
    background-color: #1e90ff !important;
}

.x-menu {
    background-color: #3c3c3c !important;
    border-color: #555555 !important;
}

.x-menu-item {
    color: #ffffff !important;
}

.x-menu-item-active {
    background-color: #1e90ff !important;
}

.x-btn, .x-btn-text {
    color: #ffffff !important;
    background-color: #404040 !important;
    border-color: #555555 !important;
}

.x-btn-over {
    background-color: #5a5a5a !important;
}

.x-form-field {
    background-color: #3c3c3c !important;
    color: #ffffff !important;
    border-color: #555555 !important;
}

.x-tab-panel-header {
    background-color: #404040 !important;
    border-color: #555555 !important;
}

.x-tab-strip-top .x-tab-strip-active {
    background-color: #3c3c3c !important;
}

.x-progress-bar {
    background-color: #1e90ff !important;
}

.x-statusbar {
    background-color: #404040 !important;
    border-color: #555555 !important;
    color: #ffffff !important;
}

.x-tree-node {
    color: #ffffff !important;
}

.x-tree-node-over {
    background-color: #5a5a5a !important;
}

.x-tree-selected {
    background-color: #1e90ff !important;
}
EOF

      # Create theme info file
      cat > /var/lib/deluge/.config/deluge/web/themes/dark/theme.json << 'EOF'
{
    "name": "Dark Theme",
    "description": "Dark theme for Deluge Web UI",
    "css": ["style.css"]
}
EOF

      # Set proper ownership and permissions for all created files
      chown -R deluge:deluge /var/lib/deluge/.config/deluge
      chmod 644 /var/lib/deluge/.config/deluge/web.conf
      chmod -R 755 /var/lib/deluge/.config/deluge/web
      chmod 644 /var/lib/deluge/.config/deluge/web/themes/dark/*
    '';
    deps = [ "users" ];  # Run after users are created
  };

  # Deluge web interface (runs on host network) with theme injection
  systemd.services.deluge-web = {
    description = "Deluge BitTorrent Web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "deluged.service" ];
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
    # Ensure config is applied before starting
    after = [ "deluge-config" ];
  };

  # Open firewall for Deluge web interface
  networking.firewall = {
    allowedTCPPorts = [ 8112 ];  # Deluge web interface
    allowedUDPPorts = [ 51820 ]; # WireGuard
  };

  # Ensure deluge config directory exists
  system.activationScripts.deluge-config = {
    text = ''
      mkdir -p /var/lib/deluge/.config/deluge
      chown deluge:deluge /var/lib/deluge/.config/deluge
      chmod 755 /var/lib/deluge/.config/deluge
    '';
    deps = [ "users" ];  # Run after users are created
  };
}