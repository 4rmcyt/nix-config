{
  lib,
  config,
  ...
}:{
  atuin_db_password = {
      sopsFile = ../../secrets/postgresql.yaml;
      owner = config.users.users.postgresql.name;
  };
  networking.firewall.allowedTCPPorts = lib.mkIf config.services.atuin.openFirewall [config.services.atuin.port];

  services.atuin = {
    enable = true;
    port = 8881;

    database.uri = "postgres://atuin:$(cat ${config.sops.secrets.atuin_db_password.path})@/atuin?host=/run/postgresql";
    openRegistration = true;
  };
}
