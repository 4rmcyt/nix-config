{...}: {
  imports = [
    # ./avahi
    ./cloudflared
    ./dnssec
    ./headplane
    ./headscale
    ./nfs
    ./ssh
    ./unbound
    ./tailscale
    ./traefik
    ./wireguard
  ];
}
