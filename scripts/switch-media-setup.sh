#!/usr/bin/env bash
# Media switch (TL-SG108E #2) full configuration script.
#
# All ports untagged — no VLAN config needed.
# Management IP changes from 192.168.1.112 → 192.168.30.112
# after which the switch is only reachable from the media segment (enp3s0).
#
# Run AFTER the NixOS router is up with enp3s0 on 192.168.30.1/24,
# while still connected to the switch on 192.168.1.112 (before IP change).

set -euo pipefail

SW=192.168.1.112
PASS="${SW2_PASS:?SW2_PASS not set — usage: SW2_PASS=... ./switch-media-setup.sh}"
CF=/tmp/sw2_cookie

rm -f "$CF"

echo "==> Logging in to LivingRoom_SW2 ($SW)..."
curl -sf -sc "$CF" -o /dev/null -X POST \
  -d "username=admin&password=$PASS&cpassword=&logon=Login" \
  "http://$SW/logon.cgi"

# ── System name ────────────────────────────────────────────────────────────────
echo "==> Setting system name..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null \
  "http://$SW/system_name_set.cgi?sysName=LivingRoom_SW2"

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

# ── Storm control — all 8 ports, 32768 Kbit/sec, BC+MC only ──────────────────
# UL-Frame excluded — PS5/Nintendo need unknown unicast for initial discovery.
echo "==> Setting storm control..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null -X POST \
  -d "state=1&rate=32768&stormType=2&stormType=4&sel_1=1&sel_2=1&sel_3=1&sel_4=1&sel_5=1&sel_6=1&sel_7=1&sel_8=1&applay=Apply" \
  "http://$SW/qos_storm_set.cgi"

# ── Management IP → 192.168.30.112 ───────────────────────────────────────────
# WARNING: after this the switch is unreachable on 192.168.1.112.
# It will be available at 192.168.30.112 via enp3s0 (media segment).
echo "==> Changing management IP to 192.168.30.112..."
curl -sf -b "$CF" -sc "$CF" -o /dev/null \
  "http://$SW/ip_setting.cgi?dhcpSetting=disable&ip_address=192.168.30.112&ip_netmask=255.255.255.0&ip_gateway=192.168.30.1"

# ── Save to flash ──────────────────────────────────────────────────────────────
echo "==> Saving config to flash..."
curl -sf -b "$CF" -o /dev/null "http://$SW/config_save.cgi?save=Save+Config"

echo "==> LivingRoom_SW2 done!"
echo "    Switch is now at 192.168.30.112 (media segment only)"
