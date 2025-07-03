#!/bin/bash

# Create working directory
mkdir -p /var/lib/deluge/pia
cd /var/lib/deluge/pia

# Get PIA credentials (passed as arguments)
PIA_USER="$1"
PIA_PASS="$2"

echo "=== PIA WireGuard Config Generator ==="
echo "Setting up for region: ca_ontario"

# Generate WireGuard keypair
PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)

echo "Generated keypair, public key: $PUBLIC_KEY"

# Get server list
echo "Fetching server list..."
SERVER_LIST=$(curl -s "https://serverlist.piaservers.net/vpninfo/servers/v6" | head -1)

# Find WireGuard server for ca_ontario
WG_SERVER_IP=$(echo "$SERVER_LIST" | jq -r '.regions[] | select(.id == "ca_ontario") | .servers.wg[0].ip')
WG_SERVER_CN=$(echo "$SERVER_LIST" | jq -r '.regions[] | select(.id == "ca_ontario") | .servers.wg[0].cn')
META_SERVER_IP=$(echo "$SERVER_LIST" | jq -r '.regions[] | select(.id == "ca_ontario") | .servers.meta[0].ip')

if [ -z "$WG_SERVER_IP" ] || [ "$WG_SERVER_IP" = "null" ]; then
  echo "Failed to find WireGuard server for ca_ontario"
  exit 1
fi

echo "Using WG server: $WG_SERVER_IP ($WG_SERVER_CN)"
echo "Using Meta server: $META_SERVER_IP"

# Get auth token
echo "Getting auth token..."
TOKEN_RESPONSE=$(curl -s -u "$PIA_USER:$PIA_PASS" \
  "https://$META_SERVER_IP/authv3/generateToken" \
  --connect-timeout 15 \
  --max-time 30 \
  --insecure)

TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token // empty')

if [ -z "$TOKEN" ]; then
  echo "Failed to get auth token"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

echo "Got auth token successfully"

# Add public key
echo "Adding public key to PIA..."
ADD_KEY_RESPONSE=$(curl -s -G \
  --data-urlencode "pubkey=$PUBLIC_KEY" \
  --data-urlencode "pt=$TOKEN" \
  "https://$WG_SERVER_IP:1337/addKey" \
  --connect-timeout 15 \
  --max-time 30 \
  --insecure)

# Extract response data
if ! echo "$ADD_KEY_RESPONSE" | jq empty 2>/dev/null; then
  echo "Invalid response from addKey"
  echo "Response: $ADD_KEY_RESPONSE"
  exit 1
fi

if [ "$(echo "$ADD_KEY_RESPONSE" | jq -r '.status // empty')" != "OK" ]; then
  echo "AddKey failed"
  echo "Response: $ADD_KEY_RESPONSE"
  exit 1
fi

SERVER_PUBLIC_KEY=$(echo "$ADD_KEY_RESPONSE" | jq -r '.server_key')
CLIENT_IP=$(echo "$ADD_KEY_RESPONSE" | jq -r '.peer_ip')
SERVER_VIP=$(echo "$ADD_KEY_RESPONSE" | jq -r '.server_vip // empty')

if [ -z "$SERVER_PUBLIC_KEY" ] || [ -z "$CLIENT_IP" ]; then
  echo "Failed to extract server key or client IP"
  echo "Response: $ADD_KEY_RESPONSE"
  exit 1
fi

echo "Key added successfully!"
echo "Client IP: $CLIENT_IP"
echo "Server Public Key: $SERVER_PUBLIC_KEY"

# Create WireGuard config file
cat > /tmp/wg.conf << EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $CLIENT_IP

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $WG_SERVER_IP:1337
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "Generated WireGuard config:"
cat /tmp/wg.conf

# Save the extracted values for our WireGuard service
echo "$PRIVATE_KEY" > /var/lib/deluge/pia/private_key
echo "$SERVER_PUBLIC_KEY" > /var/lib/deluge/pia/peer_key  
echo "$CLIENT_IP" > /var/lib/deluge/pia/client_ip
echo "$WG_SERVER_IP:1337" > /var/lib/deluge/pia/endpoint

# Set proper permissions
chmod 600 /var/lib/deluge/pia/*
chown deluge:deluge /var/lib/deluge/pia/*

# Also copy the full config for reference
cp /tmp/wg.conf /var/lib/deluge/pia/wg.conf
chown deluge:deluge /var/lib/deluge/pia/wg.conf

echo "PIA WireGuard configuration setup complete!"