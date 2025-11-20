{
  lib,
  config,
  ...
}:{
  sops.secrets = {
    atuin_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "atuin_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
  };
  networking.firewall.allowedTCPPorts = lib.mkIf config.services.atuin.openFirewall [config.services.atuin.port];

  services.atuin = {
    enable = true;
    port = 8881;

    database.uri = "postgres://atuin:${config.sops.secrets.atuin_db_password.path}@/atuin?host=/run/postgresql";
    openRegistration = true;
  };
}
