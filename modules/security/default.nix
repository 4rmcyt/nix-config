{...}: {
  imports = [
    ./fail2ban
    ./lldap      # Uncomment when SOPS secrets are configured
    ./authelia   # Uncomment when SOPS secrets are configured (requires lldap, mysql, redis)
  ];
}
