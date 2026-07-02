# nftables firewall for the router.
#
# Zone model:
#   trusted = vlan10 + enp4s0   192.168.1.0/24    office switch (wired) + ISP AP (WiFi)
#   iot     = vlan20             192.168.20.0/24   office switch port 2 → AC1750 OpenWrt
#   media   = enp3s0             192.168.30.0/24   media switch (physical port, no VLAN)
#   work    = vlan40             192.168.40.0/24   office switch port 7
#   wan     = enp1s0             DHCP from ISP router
#   ts      = tailscale0
#
# Forward policy matrix (default: deny between zones):
#   trusted → iot    : allow
#   trusted → media  : allow
#   trusted → work   : deny (work isolated even from trusted)
#   iot     → trusted: tcp 8123 (Home Assistant)
#   iot     → media  : tcp 8060 (Roku ECP)
#   iot     → *      : deny otherwise
#   media   → trusted: tcp 8096,8920 (Jellyfin), 9292 (Audiobookshelf), 80,443 (Traefik) + udp 1900,7359 (SSDP/DLNA)
#   media   → *      : deny otherwise
#   work    → *      : deny (fully isolated)
#   * → wan          : allow (masquerade NAT)
#   wan → *          : deny except ct established/related
#
# Tailscale interface (ts) is treated as trusted for SSH + exporter access.
_: {
  networking.nftables = {
    enable = true;
    ruleset = ''
      # ── Named sets ──────────────────────────────────────────────────────
      define TRUSTED_NET = 192.168.1.0/24
      define IOT_NET     = 192.168.20.0/24
      define MEDIA_NET   = 192.168.30.0/24
      define WORK_NET    = 192.168.40.0/24

      # trusted zone = vlan10 (office switch wired) + enp4s0 (ISP AP)
      define TRUSTED_IFS = { "vlan10", "enp4s0" }   # PLACEHOLDER — match apInterface in networking.nix
      define IOT_IF      = "vlan20"
      define MEDIA_IF    = "enp3s0"                  # PLACEHOLDER — match mediaInterface in networking.nix
      define WORK_IF     = "vlan40"
      define WAN_IF      = "enp1s0"                  # PLACEHOLDER — match wanInterface in networking.nix
      define TS_IF       = "tailscale0"

      define JELLYFIN_TCP = { 8096, 8920 }

      # ── Table: inet global ───────────────────────────────────────────────
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

          iif lo accept
          ct state established,related accept
          ct state invalid drop

          # ICMP: trusted + tailscale only
          iifname $TRUSTED_IFS ip protocol icmp accept
          iifname $TS_IF ip protocol icmp accept

          # DNS: trusted, iot, media → unbound on this router
          iifname { $TRUSTED_IFS, $IOT_IF, $MEDIA_IF } udp dport 53 accept
          iifname { $TRUSTED_IFS, $IOT_IF, $MEDIA_IF } tcp dport 53 accept

          # SSH: rate limit 5 new connections/minute per IP
          iifname { $TRUSTED_IFS, $TS_IF } tcp dport 22 \
            ct state new \
            add @ssh_ratelimit { ip saddr limit rate over 5/minute } \
            drop
          iifname { $TRUSTED_IFS, $TS_IF } tcp dport 22 accept

          # mDNS: trusted/iot/media for Avahi reflector
          iifname { $TRUSTED_IFS, $IOT_IF, $MEDIA_IF } udp dport 5353 accept

          # Tailscale UDP
          udp dport 41641 accept

          # Prometheus exporters: tailscale only (homeserver scrapes via tailnet)
          iifname $TS_IF tcp dport { 9100, 9167, 9547 } accept

          log prefix "nft-input-drop: " drop
        }

        # ── FORWARD (inter-zone and zone→wan routing) ────────────────────
        chain forward {
          type filter hook forward priority filter; policy drop;

          ct state established,related accept
          ct state invalid drop

          # trusted → iot: allow
          iifname $TRUSTED_IFS oifname $IOT_IF accept

          # trusted → media: allow
          iifname $TRUSTED_IFS oifname $MEDIA_IF accept

          # trusted → work: deny (falls through)

          # media → trusted: Jellyfin + Audiobookshelf + Traefik + discovery
          iifname $MEDIA_IF oifname $TRUSTED_IFS tcp dport $JELLYFIN_TCP accept
          iifname $MEDIA_IF oifname $TRUSTED_IFS tcp dport 9292 accept
          iifname $MEDIA_IF oifname $TRUSTED_IFS tcp dport { 80, 443 } accept
          iifname $MEDIA_IF oifname $TRUSTED_IFS udp dport { 1900, 7359 } accept

          # iot → trusted: Home Assistant only
          iifname $IOT_IF oifname $TRUSTED_IFS tcp dport 8123 accept

          # iot → media: Roku ECP
          iifname $IOT_IF oifname $MEDIA_IF tcp dport 8060 accept

          # * → wan: allow (masquerade in postrouting)
          oifname $WAN_IF accept

          # Tailscale routing
          iifname $TS_IF accept
          oifname $TS_IF accept

          log prefix "nft-forward-drop: " drop
        }

        # ── POSTROUTING (masquerade NAT) ────────────────────────────────
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;

          ip saddr $TRUSTED_NET oifname $WAN_IF masquerade
          ip saddr $IOT_NET     oifname $WAN_IF masquerade
          ip saddr $MEDIA_NET   oifname $WAN_IF masquerade
          ip saddr $WORK_NET    oifname $WAN_IF masquerade
        }
      }
    '';
  };
}
