{...}: {
  imports = [
    ./cloudflared
    ./dnssec
    ./nginx
    ./tailscale
    ./traefik
    ./wireguard
  ];
}
