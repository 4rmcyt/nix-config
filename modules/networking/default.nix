{...}: {
  imports = [
    ./caddy-homeserver
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
