{...}: {
  imports = [
    ./caddy-homeserver
    ./cloudflared
    ./dnssec
    ./headscale
    ./nfs
    ./ssh
    ./tailscale
    ./ua-exit
    ./unbound
    ./wireguard
  ];
}
