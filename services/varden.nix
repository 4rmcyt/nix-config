{
  pkgs,
  lib,
  config,
  ...
}:
{
  environment.systemPackages = [
      pkgs.vaultwarden-postgresql
      pkgs.linkwarden
    ];

  config = lib.mkIf config.services.vaultwarden.enable {
    # The service
    services.vaultwarden = {
      dbBackend = "postgresql";
      config = {
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        DOMAIN = "https://vault.labhome.work";
        SIGNUPS_ALLOWED = true;
        ADMIN_TOKEN = "$argon2id$v=19$m=65540,t=3,p=4$...";
        LOG_FILE = "/var/lib/bitwarden_rs/access.log";
      };
    };
    services.linkwarden = {
      enable = true;
      package = mypkgs.linkwarden;
      settingsFile = config.sops.secrets.linkwarden_settings.path;
      settings = {
        NEXT_PUBLIC_DISABLE_REGISTRATION = "false";
        VIRTUAL_PORT = "12522";
        VIRTUAL_HOST = "link.labhome.work";

      };
    }; 
  };
}
