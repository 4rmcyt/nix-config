nix
# modules/services/miniflux/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets = {
    miniflux_creds = {
      sopsFile = ../../../secrets/miniflux.yaml;
      key = "miniflux_admin_creds";
      owner = config.users.users.miniflux.name;
      group = config.users.groups.miniflux.name;
      mode = "0400"; # Or 0440 if miniflux user is in the group
    };
    miniflux_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "miniflux_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
  };

  users.users.miniflux = {
    isSystemUser = true;
    group = "miniflux";
    extraGroups = [ "users" ];
  };
  users.groups.miniflux = { };

  networking.firewall.allowedTCPPorts = [
    8086 # Miniflux
  ];

  environment.systemPackages = [ pkgs.miniflux ];

  services.miniflux = {
    enable = true;
    # Remove or comment out this line:
    # adminCredentialsFile = config.sops.secrets.miniflux_creds.path;

    config = {
      WORKER_POOL_SIZE = "5";
      POLLING_FREQUENCY = "60";
      BATCH_SIZE = "100";
      CLEANUP_ARCHIVE_READ_DAYS = "60";
      BASE_URL = "https://miniflux.labhome.work";
      LISTEN_ADDR = "localhost:8086";
      DATABASE_MIGRATIONS = 1;
      DATABASE_URL = lib.mkForce "user=miniflux password=${config.sops.secrets.miniflux_db_password.path} dbname=miniflux sslmode=disable host=/run/postgresql";

      # Add this to set environment variables from the decrypted secret
      environmentVariables = let
        # Read the decrypted secret content
        minifluxCreds = builtins.readFile config.sops.secrets.miniflux_creds.path;
        # Split the content by ":" to get username and password
        credsList = lib.splitString ":" minifluxCreds;
        username = lib.elemAt credsList 0;
        password = lib.elemAt credsList 1;
      in {
        ADMIN_USERNAME = username;
        ADMIN_PASSWORD = password;
        # Include other environment variables if needed, like DATABASE_URL, etc.
        # Note: DATABASE_URL is already set in 'config', but if you prefer
        # environment variables for everything, you could move it here.
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/miniflux 0755 miniflux miniflux -"
    "d /var/lib/miniflux/cache 0755 miniflux miniflux -"
    "d /var/lib/miniflux/logs 0755 miniflux miniflux -"
    "d /var/lib/miniflux/data 0755 miniflux miniflux -"
  ];
}
