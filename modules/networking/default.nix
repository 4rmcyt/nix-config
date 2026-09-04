{...}: {
  imports = [
    ./cloudflared
    ./dnssec
    ./headscale
    ./nfs
    ./ssh
    ./tailscale
    ./traefik
    ./unbound
    ./wireguard
    # Not in use, kept for reference:
    # ./avahi
  ];
}
