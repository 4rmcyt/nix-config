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
    ./ua-exit
    ./unbound
    ./wireguard
  ];
}
