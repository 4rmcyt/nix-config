{
  lib,
  config,
  ...
}: {
  sops.secrets = {
    atuin_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "atuin_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0400";
    };
  };

  sops.templates."atuin-env".content = ''
    ATUIN_DB_URI=postgresql://atuin:${config.sops.placeholder.atuin_db_password}@localhost/atuin?host=/run/postgresql
  '';

  networking.firewall.allowedTCPPorts = lib.mkIf config.services.atuin.openFirewall [config.services.atuin.port];

  services.atuin = {
    enable = true;
    port = config.my.network.ports.atuin;
    database.uri = null; # Use EnvironmentFile instead
    openRegistration = true;
  };

  systemd.services.atuin.serviceConfig.EnvironmentFile = config.sops.templates."atuin-env".path;
}
