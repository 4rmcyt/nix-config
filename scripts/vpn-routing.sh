#!/bin/bash

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
ip link set wg-deluge up || true

# Configure interface IP
ip addr add $CLIENT_IP/32 dev wg-deluge || true

# Add peer configuration
wg set wg-deluge peer $PEER_KEY \
  allowed-ips 0.0.0.0/0 \
  endpoint $ENDPOINT \
  persistent-keepalive 25

# Setup routing table for deluge user (UID 994)
ip route add default dev wg-deluge table 42 || true
ip rule add uidrange 994-994 table 42 || true

# Flush route cache
ip route flush cache

echo "VPN routing configured successfully"

# Test connectivity
echo "Testing VPN connectivity..."
wg show wg-deluge