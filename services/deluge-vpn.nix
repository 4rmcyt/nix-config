
{ config, pkgs, lib, ... }:

let
  # Enhanced PIA setup script with port forwarding
  pia-setup-script = pkgs.writeShellScript "pia-setup.sh" ''
    set -euo pipefail

    PIA_DIR="/var/lib/deluge/pia"
    WG_CONFIG="$PIA_DIR/wg0.conf"
    PORT_FILE="$PIA_DIR/forwarded_port"

    mkdir -p "$PIA_DIR"
    chmod 700 "$PIA_DIR"

    # Read PIA credentials
    PIA_USER="$(cat ${config.sops.secrets.pia_username.path})"
    PIA_PASS="$(cat ${config.sops.secrets.pia_password.path})"

    echo "🔐 Authenticating with PIA..."

    # Get auth token
    AUTH_RESPONSE=$(${pkgs.curl}/bin/curl -s -u "$PIA_USER:$PIA_PASS" \
      "https://privateinternetaccess.com/api/client/v2/token")

    if ! echo "$AUTH_RESPONSE" | ${pkgs.jq}/bin/jq -e '.token' > /dev/null; then
      echo "❌ PIA authentication failed"
      exit 1
    fi

    TOKEN=$(echo "$AUTH_RESPONSE" | ${pkgs.jq}/bin/jq -r '.token')
    echo "✅ PIA authentication successful"

    # Get optimal server list (port forwarding enabled)
    echo "🌍 Finding optimal PF-enabled server..."
    SERVERS_RESPONSE=$(${pkgs.curl}/bin/curl -s \
      "https://serverlist.piaservers.net/vpninfo/servers/v6")

    # Filter for port forwarding enabled servers and select best one
    BEST_SERVER=$(echo "$SERVERS_RESPONSE" | ${pkgs.jq}/bin/jq -r '
      .regions[] | select(.port_forward == true and .geo == true) |
      select(.country == "US" or .country == "CA" or .country == "NL") |
      .servers.wg[0]
    ' | head -1)

    if [ -z "$BEST_SERVER" ]; then
      echo "❌ No suitable PF servers found"
      exit 1
    fi

    SERVER_IP=$(echo "$BEST_SERVER" | ${pkgs.jq}/bin/jq -r '.ip')
    SERVER_CN=$(echo "$BEST_SERVER" | ${pkgs.jq}/bin/jq -r '.cn')
    SERVER_PORT=$(echo "$BEST_SERVER" | ${pkgs.jq}/bin/jq -r '.port')

    echo "📍 Selected server: $SERVER_CN ($SERVER_IP:$SERVER_PORT)"

    # Generate WireGuard key pair
    PRIVATE_KEY=$(${pkgs.wireguard-tools}/bin/wg genkey)
    PUBLIC_KEY=$(echo "$PRIVATE_KEY" | ${pkgs.wireguard-tools}/bin/wg pubkey)

    # Add key to PIA
    echo "🔑 Registering WireGuard key with PIA..."
    ADD_KEY_RESPONSE=$(${pkgs.curl}/bin/curl -s \
      -H "Authorization: Token $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"pubkey\":\"$PUBLIC_KEY\"}" \
      "https://$SERVER_CN:19999/addKey")

    if ! echo "$ADD_KEY_RESPONSE" | ${pkgs.jq}/bin/jq -e '.status == "OK"' > /dev/null; then
      echo "❌ Failed to add WireGuard key"
      exit 1
    fi

    PEER_IP=$(echo "$ADD_KEY_RESPONSE" | ${pkgs.jq}/bin/jq -r '.peer_ip')
    SERVER_PUBLIC_KEY=$(echo "$ADD_KEY_RESPONSE" | ${pkgs.jq}/bin/jq -r '.server_key')

    echo "✅ WireGuard key registered. Client IP: $PEER_IP"

    # Create WireGuard configuration
    cat > "$WG_CONFIG" << EOF
    [Interface]
    PrivateKey = $PRIVATE_KEY
    Address = $PEER_IP/32
    DNS = 10.0.0.243

    [Peer]
    PublicKey = $SERVER_PUBLIC_KEY
    Endpoint = $SERVER_IP:$SERVER_PORT
    AllowedIPs = 0.0.0.0/0
    PersistentKeepalive = 25
    EOF

    chmod 600 "$WG_CONFIG"
    echo "📝 WireGuard config created"

    # Setup port forwarding
    echo "🔌 Setting up port forwarding..."

    # Request port forward
    PF_RESPONSE=$(${pkgs.curl}/bin/curl -s \
      -H "Authorization: Token $TOKEN" \
      "https://$SERVER_CN:19999/getSignature?token=$TOKEN")

    if echo "$PF_RESPONSE" | ${pkgs.jq}/bin/jq -e '.status == "OK"' > /dev/null; then
      SIGNATURE=$(echo "$PF_RESPONSE" | ${pkgs.jq}/bin/jq -r '.signature')
      PAYLOAD=$(echo "$PF_RESPONSE" | ${pkgs.jq}/bin/jq -r '.payload')

      # Bind the port
      BIND_RESPONSE=$(${pkgs.curl}/bin/curl -s \
        -H "Authorization: Token $TOKEN" \
        -d "payload=$PAYLOAD&signature=$SIGNATURE" \
        "https://$SERVER_CN:19999/bindPort")

      if echo "$BIND_RESPONSE" | ${pkgs.jq}/bin/jq -e '.status == "OK"' > /dev/null; then
        FORWARDED_PORT=$(echo "$BIND_RESPONSE" | ${pkgs.jq}/bin/jq -r '.port')
        echo "$FORWARDED_PORT" > "$PORT_FILE"
        echo "✅ Port forwarding enabled: $FORWARDED_PORT"
      else
        echo "⚠️  Port forwarding failed, continuing without"
        echo "0" > "$PORT_FILE"
      fi
    else
      echo "⚠️  Port forwarding not available, continuing without"
      echo "0" > "$PORT_FILE"
    fi

    echo "🚀 PIA WireGuard setup complete!"
  '';

  # Port forwarding renewal script
  pia-port-refresh = pkgs.writeShellScript "pia-port-refresh.sh" ''
    set -euo pipefail

    PORT_FILE="/var/lib/deluge/pia/forwarded_port"
    DELUGE_CONFIG="/var/lib/deluge/.config/deluge/core.conf"

    if [ ! -f "$PORT_FILE" ]; then
      echo "No port file found, skipping refresh"
      exit 0
    fi

    CURRENT_PORT=$(cat "$PORT_FILE")

    if [ "$CURRENT_PORT" = "0" ]; then
      echo "Port forwarding not active"
      exit 0
    fi

    echo "Updating Deluge with port: $CURRENT_PORT"

    # Update Deluge configuration
    ${pkgs.python3}/bin/python3 << EOF
    import json
    import os

    config_file = "$DELUGE_CONFIG"
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            config = json.load(f)

        config['listen_ports'] = [$CURRENT_PORT, $CURRENT_PORT]
        config['random_port'] = False

        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)

        print(f"Updated Deluge to use port {$CURRENT_PORT}")
    EOF

    # Restart deluge to apply changes
    systemctl restart deluge-vpn
  '';
in
{
  # SOPS secrets for PIA
  sops.secrets.pia_username = {
    owner = "deluge";
    group = "deluge";
    mode = "0400";
  };
  sops.secrets.pia_password = {
    owner = "deluge";
    group = "deluge";
    mode = "0400";
  };

  # Deluge VPN service with enhanced configuration
  systemd.services.deluge-vpn = {
    description = "Deluge BitTorrent daemon with PIA VPN";
    after = [ "network.target" "systemd-resolved.service" ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "systemd-resolved.service" ];

    preStart = ''
      # Run PIA setup
      ${pia-setup-script}

      # Wait for setup completion
      sleep 5

      # Configure network namespace
      ${pkgs.iproute2}/bin/ip netns add deluge-vpn || true
      ${pkgs.iproute2}/bin/ip link add veth-deluge type veth peer name veth-deluge-ns
      ${pkgs.iproute2}/bin/ip link set veth-deluge-ns netns deluge-vpn
      ${pkgs.iproute2}/bin/ip addr add 10.10.10.1/24 dev veth-deluge
      ${pkgs.iproute2}/bin/ip link set veth-deluge up

      # Setup namespace network
      ${pkgs.iproute2}/bin/ip netns exec deluge-vpn ip addr add 10.10.10.2/24 dev veth-deluge-ns
      ${pkgs.iproute2}/bin/ip netns exec deluge-vpn ip link set veth-deluge-ns up
      ${pkgs.iproute2}/bin/ip netns exec deluge-vpn ip link set lo up

      # Start WireGuard in namespace
      ${pkgs.iproute2}/bin/ip netns exec deluge-vpn ${pkgs.wireguard-tools}/bin/wg-quick up /var/lib/deluge/pia/wg0.conf

      # Setup NAT for local access
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o wg0 -j MASQUERADE || true
      ${pkgs.iptables}/bin/iptables -A FORWARD -i veth-deluge -o wg0 -j ACCEPT || true
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -o veth-deluge -j ACCEPT || true

      # Port forwarding for web UI
      ${pkgs.iptables}/bin/iptables -t nat -A PREROUTING -p tcp --dport 8112 -j DNAT --to-destination 10.10.10.2:8112 || true

      # Ensure deluge directories exist
      mkdir -p /var/lib/deluge/.config/deluge
      mkdir -p /home/zeev/Downloads
      chown -R deluge:deluge /var/lib/deluge
      chown -R deluge:deluge /home/zeev/Downloads

      # Wait for port assignment
      sleep 10

      # Update Deluge with forwarded port
      ${pia-port-refresh}
    '';

    serviceConfig = {
      Type = "forking";
      User = "deluge";
      Group = "deluge";
      UMask = "0002";

      # Run deluge in network namespace
      ExecStart = "${pkgs.iproute2}/bin/ip netns exec deluge-vpn ${pkgs.deluge}/bin/deluged -d -c /var/lib/deluge/.config/deluge -L info";
      ExecStartPost = "${pkgs.iproute2}/bin/ip netns exec deluge-vpn ${pkgs.deluge}/bin/deluge-web -c /var/lib/deluge/.config/deluge -L info --fork";

      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutSec = "300s";

      # Security settings
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/deluge" "/home/zeev/Downloads" "/tmp" ];
      ProtectHome = "read-only";
      NoNewPrivileges = true;

      # Network namespace capabilities
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
    };

    preStop = ''
      # Gracefully stop services
      ${pkgs.iproute2}/bin/ip netns exec deluge-vpn pkill deluge-web || true
      ${pkgs.iproute2}/bin/ip netns exec deluge-vpn pkill deluged || true
      sleep 5
    '';

    postStop = ''
      # Cleanup network namespace
      ${pkgs.wireguard-tools}/bin/wg-quick down /var/lib/deluge/pia/wg0.conf || true
      ${pkgs.iproute2}/bin/ip netns delete deluge-vpn || true
      ${pkgs.iproute2}/bin/ip link delete veth-deluge || true

      # Cleanup iptables rules
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o wg0 -j MASQUERADE || true
      ${pkgs.iptables}/bin/iptables -D FORWARD -i veth-deluge -o wg0 -j ACCEPT || true
      ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -o veth-deluge -j ACCEPT || true
      ${pkgs.iptables}/bin/iptables -t nat -D PREROUTING -p tcp --dport 8112 -j DNAT --to-destination 10.10.10.2:8112 || true
    '';
  };

  # Port refresh timer (every 15 minutes)
  systemd.services.deluge-port-refresh = {
    description = "Refresh PIA port forwarding for Deluge";
    serviceConfig = {
      Type = "oneshot";
      User = "deluge";
      Group = "deluge";
      ExecStart = "${pia-port-refresh}";
    };
  };

  systemd.timers.deluge-port-refresh = {
    description = "Refresh PIA port forwarding timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "20min";
      OnUnitActiveSec = "15min";
      RandomizedDelaySec = "5min";
    };
  };

  # Deluge user configuration
  users.users.deluge = {
    isSystemUser = true;
    group = "deluge";
    home = "/var/lib/deluge";
    createHome = true;
  };

  users.groups.deluge = {};

  # CLEANED: Only service-specific packages (removed duplicates)
  environment.systemPackages = with pkgs; [
    deluge        # ✅ Service-specific
    iptables      # ✅ Not found elsewhere
    jq            # ✅ Not found elsewhere
    # REMOVED: wireguard-tools, iproute2, curl (already in configuration.nix)
  ];

  # Firewall configuration
  networking.firewall = {
    allowedTCPPorts = [ 8112 ];  # Deluge web UI
    # Note: BitTorrent port is handled dynamically by PIA port forwarding
  };

  # REMOVED: IP forwarding configuration (now handled by tailscale.nix)
  # This prevents duplicate sysctl definitions
}