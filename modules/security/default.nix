{...}: {
  imports = [
    ./crowdsec
    # ./cowrie  # Disabled
    ./fail2ban
    ./kanidm
    ./kanidm/unix-client.nix
    # ./lldap    # Not needed — Tailscale handles access control
    # ./authelia # Not needed — Tailscale handles access control
  ];
}
