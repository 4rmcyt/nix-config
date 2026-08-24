{...}: {
  imports = [
    # ./avahi
    ./cloudflared
    ./dnssec
    ./headscale
    ./nfs
    ./ssh
    ./tailscale
    ./traefik
    ./unbound
    ./wireguard
  ];
}
