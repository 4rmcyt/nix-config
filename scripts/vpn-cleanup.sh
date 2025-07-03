#!/bin/bash

echo "Cleaning up VPN routing..."
ip rule del uidrange 993-993 table 42 || true
ip route flush table 42 || true
wg set wg-deluge peer remove || true