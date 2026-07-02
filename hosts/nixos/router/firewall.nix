# nftables firewall for the router.
#
# Zone model (maps 1:1 to VLAN interfaces):
#   trusted = vlan10  192.168.1.0/24
#   iot     = vlan20  192.168.20.0/24
#   media   = vlan30  192.168.30.0/24
#   work    = vlan40  192.168.40.0/24
#   wan     = enp1s0  (DHCP from ISP router)
#   ts      = tailscale0
#
# Forward policy matrix (default: deny between zones):
#   trusted → iot    : allow
#   trusted → media  : allow
#   iot     → *      : deny (all zones)
#   media   → trusted: tcp 8096,8920 (Jellyfin), 9292 (Audiobookshelf), 80,443 (Traefik) + udp 1900,7359 (SSDP/DLNA)
#   media   → *      : deny otherwise
#   work    → *      : deny (fully isolated)
#   * → wan          : allow (masquerade NAT)
#   wan → *          : deny except ct established/related
#
# Tailscale interface (ts) is treated as trusted for SSH access to the router itself.
_: {
  networking.nftables = {
    enable = true;
    ruleset = ''
      # ── Named sets ──────────────────────────────────────────────────────
      # Avoids repeating subnets in rules; makes intent explicit.

      define TRUSTED_NET = 192.168.1.0/24
      define IOT_NET     = 192.168.20.0/24
      define MEDIA_NET   = 192.168.30.0/24
      define WORK_NET    = 192.168.40.0/24

      define TRUSTED_IF  = "vlan10"
      define IOT_IF      = "vlan20"
      define MEDIA_IF    = "vlan30"
      define WORK_IF     = "vlan40"
      define WAN_IF      = "enp1s0"   # PLACEHOLDER — match wanInterface in networking.nix
      define TS_IF       = "tailscale0"

      # Jellyfin ports media zone is allowed to reach in trusted
      define JELLYFIN_TCP = { 8096, 8920 }

      # ── Table: inet global ───────────────────────────────────────────────
      # Handles all IPv4/IPv6 (IPv6 disabled on this host, but the table
      # family inet is idiomatic for future-proofing without extra effort).

      table inet global {

        # ── Rate limit sets ──────────────────────────────────────────────
        set ssh_ratelimit {
          type ipv4_addr
          flags dynamic
          timeout 60s
        }

        # ── INPUT (traffic destined for the router itself) ───────────────
        chain input {
          type filter hook input priority filter; policy drop;

          # Loopback: always accept
          iif lo accept

          # Established/related connections: accept (stateful tracking)
          ct state established,related accept

          # Invalid: drop silently
          ct state invalid drop

          # ICMP: allow ping from trusted/tailscale only (not from iot/media/wan)
          iifname { $TRUSTED_IF, $TS_IF } ip protocol icmp accept

          # DNS: trusted, iot, media clients → unbound on this router
          iifname { $TRUSTED_IF, $IOT_IF, $MEDIA_IF } udp dport 53 accept
          iifname { $TRUSTED_IF, $IOT_IF, $MEDIA_IF } tcp dport 53 accept

          # SSH: rate limit to 5 new connections per minute per IP
          iifname { $TRUSTED_IF, $TS_IF } tcp dport 22 \
            ct state new \
            add @ssh_ratelimit { ip saddr limit rate over 5/minute } \
            drop
          iifname { $TRUSTED_IF, $TS_IF } tcp dport 22 accept

          # mDNS: allow from trusted/iot/media for Avahi reflector
          iifname { $TRUSTED_IF, $IOT_IF, $MEDIA_IF } udp dport 5353 accept

          # Tailscale itself needs UDP 41641
          udp dport 41641 accept

          # Prometheus exporters: only from Tailscale (homeserver scrapes via tailnet)
          # 9100 node_exporter, 9167 unbound_exporter, 9547 kea_exporter
          iifname $TS_IF tcp dport { 9100, 9167, 9547 } accept

          # Everything else → drop (logged for diagnostics)
          log prefix "nft-input-drop: " drop
        }

        # ── FORWARD (inter-zone and zone→wan routing) ────────────────────
        chain forward {
          type filter hook forward priority filter; policy drop;

          # Stateful: established/related always pass
          ct state established,related accept
          ct state invalid drop

          # ── trusted → iot: allow ────────────────────────────────────
          iifname $TRUSTED_IF oifname $IOT_IF accept

          # ── trusted → media: allow ──────────────────────────────────
          iifname $TRUSTED_IF oifname $MEDIA_IF accept

          # ── trusted → work: deny (work is isolated, even from trusted)
          # (falls through to default drop)

          # ── media → trusted: Jellyfin + Audiobookshelf + Traefik + discovery
          iifname $MEDIA_IF oifname $TRUSTED_IF tcp dport $JELLYFIN_TCP accept
          iifname $MEDIA_IF oifname $TRUSTED_IF tcp dport 9292 accept
          iifname $MEDIA_IF oifname $TRUSTED_IF tcp dport { 80, 443 } accept
          iifname $MEDIA_IF oifname $TRUSTED_IF udp dport { 1900, 7359 } accept
          # All other media→trusted: deny (falls through)

          # ── iot → trusted: Home Assistant only ─────────────────────
          iifname $IOT_IF oifname $TRUSTED_IF tcp dport 8123 accept

          # ── iot → media: Roku app control (ECP) ────────────────────
          iifname $IOT_IF oifname $MEDIA_IF tcp dport 8060 accept

          # ── media → iot, work: deny (falls through) ─────────────────

          # ── iot → *: deny (falls through) ───────────────────────────

          # ── work → *: deny (falls through) ──────────────────────────

          # ── * → wan: allow (all zones can reach WAN) ────────────────
          oifname $WAN_IF accept

          # ── Tailscale routing (router-as-ts-subnet-relay) ───────────
          # traffic arriving from/going to tailscale0 passes freely;
          # Tailscale ACLs handle policy there.
          iifname $TS_IF accept
          oifname $TS_IF accept

          # Catch-all drop with log prefix for debugging
          log prefix "nft-forward-drop: " drop
        }

        # ── POSTROUTING (source NAT / masquerade) ────────────────────────
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;

          # Masquerade all four VLAN subnets going out to WAN.
          # Double-NAT is intentional — ISP router is upstream.
          ip saddr $TRUSTED_NET oifname $WAN_IF masquerade
          ip saddr $IOT_NET     oifname $WAN_IF masquerade
          ip saddr $MEDIA_NET   oifname $WAN_IF masquerade
          ip saddr $WORK_NET    oifname $WAN_IF masquerade
        }
      }
    '';
  };
}
