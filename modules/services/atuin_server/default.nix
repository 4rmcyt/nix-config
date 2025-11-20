{
  lib,
  config,
  ...
}: {
  sops.secrets = {
    atuin_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "atuin_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
  };

  sops.templates."atuin-env".content = ''
    ATUIN_DB_URI=postgresql://atuin:${config.sops.placeholder.atuin_db_password}@localhost/atuin?host=/run/postgresql
  '';

  networking.firewall.allowedTCPPorts = lib.mkIf config.services.atuin.openFirewall [config.services.atuin.port];

  services.atuin = {
    enable = true;
    port = 8881;
    database.uri = null; # Use EnvironmentFile instead
    openRegistration = true;
  };

  # Configure systemd service to use the environment file
  systemd.services.atuin.serviceConfig.EnvironmentFile = config.sops.templates."atuin-env".path;
}
