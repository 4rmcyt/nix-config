{
  lib,
  config,
  pkgs,
  ...
}: let
  # Create an environment file with the database URI
  atuinEnvFile = pkgs.writeText "atuin-env" ''
    ATUIN_DB_URI=postgres://atuin:$(cat ${config.sops.secrets.atuin.path} | tr -d '\n\r')@/atuin?host=/run/postgresql
  '';
in {
  networking.firewall.allowedTCPPorts = lib.mkIf config.services.atuin.openFirewall [config.services.atuin.port];

  services.atuin = {
    enable = true;
    port = 8881;
    openRegistration = true;
    # Set to null so we can provide it via EnvironmentFile
    database.uri = null;
  };

  # Override the systemd service to use EnvironmentFile for the database URI
  systemd.services.atuin = {
    preStart = lib.mkBefore ''
      # Generate the environment file with the actual password at runtime
      echo "ATUIN_DB_URI=postgres://atuin:$(cat ${config.sops.secrets.atuin.path} | tr -d '\n\r')@/atuin?host=/run/postgresql" > /run/atuin/db-uri.env
    '';
    serviceConfig = {
      # Load the database URI from the generated environment file
      EnvironmentFile = "/run/atuin/db-uri.env";
      # Ensure the service has access to the secret
      SupplementaryGroups = lib.mkAfter [config.users.groups.postgresql.name];
      # Ensure /run/atuin exists
      RuntimeDirectory = "atuin";
    };
  };
}
