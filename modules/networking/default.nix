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
    ./ua-exit-ovpn
    ./unbound
    ./wireguard
  ];
}
