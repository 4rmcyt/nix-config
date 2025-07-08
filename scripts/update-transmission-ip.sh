#!/usr/bin/env bash
set -e # Exit immediately if a command exits with a non-zero status.

# Give the interface a moment to be fully ready
sleep 2

# Get the IP address of the wg0 interface and nothing else.
VPN_IP=$(ip -4 addr show wg0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Path to Transmission's real settings file
SETTINGS_FILE="/var/lib/transmission/.config/transmission-daemon/settings.json"

if [ -n "$VPN_IP" ]; then
  echo "PIA Hook: Found VPN IP $VPN_IP. Updating Transmission."
  # Use jq to safely update the JSON file in-place
  jq --arg ip "$VPN_IP" '."bind-address-ipv4" = $ip' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  
  # Tell the running transmission service to reload its config
  systemctl reload transmission.service
else
  echo "PIA Hook: Could not find IP for wg0. Transmission not updated."
fi