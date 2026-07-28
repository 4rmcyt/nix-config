#!/usr/bin/env bash
# Office switch (TL-SG108E #1) full configuration script.
#
# Port layout:
#   Port 1  — router enp2s0 uplink, tagged VLAN 10/20/40
#   Port 2-6 — trusted wired devices, PVID 10
#   Port 7  — work port, PVID 40
#   Port 8  — IoT AP (AC1750 OpenWrt), PVID 20
#
# Run AFTER the NixOS router is up and you can reach 192.168.1.111.

set -euo pipefail

SW=192.168.1.111
PASS="${SW1_PASS:?SW1_PASS not set — usage: SW1_PASS=... ./switch-office-setup.sh}"
CF=/tmp/sw1_cookie

rm -f "$CF"

echo "==> Logging in to Office_SW1 ($SW)..."
curl -sf -sc "$CF" -o /dev/null -X POST \
  -d "username=admin&password=$PASS&cpassword=&logon=Login" \
  "http://$SW/logon.cgi"

# ── System name ────────────────────────────────────────────────────────────────
echo "==> Setting system name..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null \
  "http://$SW/system_name_set.cgi?sysName=Office_SW1"

# ── Management IP (stays 192.168.1.111, gateway → router vlan10) ──────────────
echo "==> Setting management IP..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null \
  "http://$SW/ip_setting.cgi?dhcpSetting=disable&ip_address=192.168.1.111&ip_netmask=255.255.255.0&ip_gateway=192.168.1.1"

# ── Loop prevention ────────────────────────────────────────────────────────────
echo "==> Enabling loop prevention..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null \
  "http://$SW/loop_prevention_set.cgi?lpEn=1&apply=Apply"

# ── IGMP Snooping ──────────────────────────────────────────────────────────────
echo "==> Enabling IGMP snooping..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null \
  "http://$SW/igmpSnooping.cgi?igmp_mode=1&reportSu_mode=1&Apply=Apply"

# ── QoS mode (port-based) ─────────────────────────────────────────────────────
echo "==> Setting QoS mode..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null -X POST \
  -d "rd_qosmode=2&qosmode=Apply" \
  "http://$SW/qos_mode_set.cgi"

# ── Storm control — all 8 ports, 8192 Kbit/sec, BC+MC+UL-Frame ───────────────
echo "==> Setting storm control..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null -X POST \
  -d "state=1&rate=8192&stormType=1&stormType=2&stormType=4&sel_1=1&sel_2=1&sel_3=1&sel_4=1&sel_5=1&sel_6=1&sel_7=1&sel_8=1&applay=Apply" \
  "http://$SW/qos_storm_set.cgi"

# ── 802.1Q VLANs ──────────────────────────────────────────────────────────────
echo "==> Creating VLAN 10 (trusted)..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null \
  "http://$SW/qvlanSet.cgi?vid=10&vname=trusted&selType_1=1&selType_2=0&selType_3=0&selType_4=0&selType_5=0&selType_6=0&selType_7=2&selType_8=2&qvlan_add=Add%2FModify"

echo "==> Creating VLAN 20 (iot)..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null \
  "http://$SW/qvlanSet.cgi?vid=20&vname=iot&selType_1=1&selType_2=2&selType_3=2&selType_4=2&selType_5=2&selType_6=2&selType_7=2&selType_8=0&qvlan_add=Add%2FModify"

echo "==> Creating VLAN 40 (work)..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null \
  "http://$SW/qvlanSet.cgi?vid=40&vname=work&selType_1=1&selType_2=2&selType_3=2&selType_4=2&selType_5=2&selType_6=2&selType_7=0&selType_8=2&qvlan_add=Add%2FModify"

# ── PVIDs ─────────────────────────────────────────────────────────────────────
echo "==> Setting PVIDs..."
# Port 1 (uplink) — PVID 1 (tagged trunk, PVID irrelevant but keep default)
curl -sf -b "$CF" -sc "$CF" -o /dev/null "http://$SW/vlanPvidSet.cgi?pbm=1&pvid=1"
# Ports 2-6 — trusted wired devices, PVID 10 (bitmask: 2+4+8+16+32 = 62)
curl -sf -b "$CF" -sc "$CF" -o /dev/null "http://$SW/vlanPvidSet.cgi?pbm=62&pvid=10"
# Port 7 — work, PVID 40 (bitmask: 64)
curl -sf -b "$CF" -sc "$CF" -o /dev/null "http://$SW/vlanPvidSet.cgi?pbm=64&pvid=40"
# Port 8 — IoT AP (AC1750 OpenWrt), PVID 20 (bitmask: 128)
curl -sf -b "$CF" -sc "$CF" -o /dev/null "http://$SW/vlanPvidSet.cgi?pbm=128&pvid=20"

# ── Save to flash ──────────────────────────────────────────────────────────────
echo "==> Saving config to flash..."
curl -sf -b "$CF" -o /dev/null "http://$SW/config_save.cgi?save=Save+Config"

echo "==> Office_SW1 done!"
