{...}: {
  imports = [
    # ./avahi
    # ./cloudflared  # Replaced by Tailscale for all internal services
    ./dnssec
    ./tailscale
    ./traefik
    ./wireguard
  ];
}
