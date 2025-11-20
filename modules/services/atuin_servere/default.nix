{
  lib,
  config,
  ...
}: {
  
    networking.firewall.allowedTCPPorts = lib.mkIf config.services.atuin.openFirewall [config.services.atuin.port];

    services.atuin = {
      enable = true;
      port = 8881;
      database.uri = "user=atuin password=${config.sops.secrets.atuin_db_password.path} dbname=atuin sslmode=disable host=/run/postgresql";
    };
    openRegistration = true;
  };
}
