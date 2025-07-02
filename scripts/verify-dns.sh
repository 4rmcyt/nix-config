#!/bin/bash
# DNS Configuration Verification Script for LabHome Server

echo "🔍 DNS Configuration Verification"
echo "=================================="
echo ""

echo "📋 Current DNS Settings:"
echo "------------------------"
echo "Primary DNS: NextDNS (2bffa2.dns.nextdns.io)"
echo "Security: DNS-over-TLS enabled"
echo "Tailscale: Uses NextDNS (accept-dns=false)"
echo "WireGuard VPN: Uses NextDNS for Deluge isolation"
echo ""

echo "🧪 DNS Resolution Tests:"
echo "------------------------"

# Test NextDNS resolution
echo "Testing NextDNS resolution..."
if dig @45.90.28.0 google.com +short > /dev/null 2>&1; then
    echo "✅ NextDNS resolution: OK"
else
    echo "❌ NextDNS resolution: FAILED"
fi

# Test DNS-over-TLS
echo "Testing DNS-over-TLS..."
if systemctl is-active systemd-resolved > /dev/null 2>&1; then
    echo "✅ systemd-resolved: Running"
    if resolvectl status | grep -q "DNS over TLS: yes"; then
        echo "✅ DNS-over-TLS: Enabled"
    else
        echo "⚠️  DNS-over-TLS: Check configuration"
    fi
else
    echo "❌ systemd-resolved: Not running"
fi

# Test Tailscale DNS
echo "Testing Tailscale DNS configuration..."
if systemctl is-active tailscale > /dev/null 2>&1; then
    if tailscale status | grep -q "100.69.40.75"; then
        echo "✅ Tailscale: Connected (IP: 100.69.40.75)"
    else
        echo "⚠️  Tailscale: IP not matching expected"
    fi
    
    # Check if Tailscale is using NextDNS
    if ! tailscale status | grep -q "DNS.*100.100.100.100"; then
        echo "✅ Tailscale DNS: Using NextDNS (not Tailscale DNS)"
    else
        echo "⚠️  Tailscale DNS: Using Tailscale DNS instead of NextDNS"
    fi
else
    echo "❌ Tailscale: Not running"
fi

echo ""
echo "🔧 Detailed DNS Information:"
echo "----------------------------"
echo "Current DNS servers:"
resolvectl status | grep "DNS Servers" || echo "Could not retrieve DNS servers"

echo ""
echo "DNS resolution test:"
nslookup google.com | head -5

echo ""
echo "Tailscale status:"
if command -v tailscale > /dev/null 2>&1; then
    tailscale status | head -5
else
    echo "Tailscale command not available"
fi

echo ""
echo "🏁 Verification complete!"
echo "For issues, check: journalctl -u systemd-resolved -u tailscale"
