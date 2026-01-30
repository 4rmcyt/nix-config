{config, ...}: {
  sops.secrets.vaultwarden_env = {
    sopsFile = ../../../secrets/vaultwarden.env;
    owner = "vaultwarden";
    group = "vaultwarden";
    mode = "0400";
    format = "dotenv";
  };

  services.vaultwarden = {
    enable = true;
    environmentFile = config.sops.secrets.vaultwarden_env.path;
    config = {
      DOMAIN = "https://vault.${config.my.defaults.domain}";
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = false;
      SHOW_PASSWORD_HINT = false;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      DATABASE_URL = "postgresql:///vaultwarden?host=/run/postgresql";
      WEBSOCKET_ENABLED = true;
      SENDS_ALLOWED = true;
      EMERGENCY_ACCESS_ALLOWED = true;
      ORG_CREATION_USERS = "none";
      LOG_LEVEL = "warn";
    };
  };

  networking.firewall.allowedTCPPorts = [
    8222
  ];
}
