{...}: {
  imports = [
    # ./avahi
    # ./cloudflared  # Replaced by Tailscale for all internal services
    ./dnssec
    ./nfs
    ./tailscale
    ./traefik
    ./wireguard
  ];
}
