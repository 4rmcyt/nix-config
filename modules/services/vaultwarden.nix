{
  pkgs,
  lib,
  config,
  ...
}:
{

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

  services.nginx.virtualHosts."vault.labhome.work" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyPass = "http://localhost:8222";
      proxyWebsockets = true;
      proxyHeaders = {
        "X-Forwarded-For" = "$proxy_add_x_forwarded_for";
        "X-Forwarded-Proto" = "https";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    8222 # Vaultwarden
  ];

  users.users.vaultwarden = {
    isSystemUser = true;
    group = "vaultwarden";
    extraGroups = [ "users" ];
  };
  users.groups.vaultwarden = { };

}
