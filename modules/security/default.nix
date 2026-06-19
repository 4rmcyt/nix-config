{...}: {
  imports = [
    ./crowdsec
    # ./cowrie  # Disabled
    ./fail2ban
    ./kanidm
    # ./lldap    # Not needed — Tailscale handles access control
    # ./authelia # Not needed — Tailscale handles access control
  ];
}
