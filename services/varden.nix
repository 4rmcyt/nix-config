{
  pkgs,
  lib,
  config,
  ...
}:
{
  environment.systemPackages = [
    pkgs.vaultwarden
    pkgs.linkwarden
  ];
  config = lib.mkIf config.services.vaultwarden.enable {
    services.vaultwarden = {
      dbBackend = "postgresql";
      config = {
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        DOMAIN = "https://vault.example.com";
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
        VIRTUAL_PORT = "12522";
        VIRTUAL_HOST = "link.example.com";
      };
    }; 
  };

  users.users.vaultwarden = {
    isSystemUser = true;
    group = "vaultwarden";
    extraGroups = [ "users"];
  };
  users.groups.vaultwarden = { };
  
  users.users.linkwarden = {
    isSystemUser = true;
    group = "linkwarden";
    extraGroups = [ "users" ];
  };
  users.groups.linkwarden = { };
}
