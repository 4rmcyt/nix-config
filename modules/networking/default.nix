{...}: {
  imports = [
    # ./avahi
    ./cloudflared
    ./dnssec
    ./headplane
    ./headscale
    ./nfs
    ./unbound
    ./tailscale
    ./traefik
    ./wireguard
  ];
}
