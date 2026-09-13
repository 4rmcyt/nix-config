{...}: {
  imports = [
    ./crowdsec
    ./fail2ban
    ./kanidm
    ./kanidm/unix-client.nix
  ];
}
