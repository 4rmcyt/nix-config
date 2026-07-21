{...}: {
  imports = [
    # ./avahi
    ./cloudflared
    ./dnssec
    ./headscale
    ./nfs
    ./ssh
    ./unbound
    ./tailscale
    ./traefik
    ./wireguard
  ];
}
