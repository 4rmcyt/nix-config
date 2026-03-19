{...}: {
  imports = [
    ./crowdsec
    ./cowrie
    ./fail2ban
    # ./lldap    # Not needed — Tailscale handles access control
    # ./authelia # Not needed — Tailscale handles access control
  ];
}
