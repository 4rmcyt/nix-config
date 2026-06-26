{...}: {
  imports = [
    ./crowdsec
    ./fail2ban
    ./hardening.nix
    ./kanidm
    ./kanidm/unix-client.nix
  ];
}
