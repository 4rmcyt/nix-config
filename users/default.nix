{ config, pkgs, ... }:

{
  users = {
    # Define all groups for your services
    groups = {
      media = {}; samba = {}; git = {}; keycloak = {};
      homepage-dashboard = {}; nextcloud = {}; microbin = {};
      paperless = {}; miniflux = {}; hass = {}; radicale = {};
      mosquitto = {}; grafana = {}; cloudflared = {};
    };

    users = {
      zeev = {
        isNormalUser = true;
        description = "Zeev";
        shell = pkgs.zsh;
        extraGroups = [ "networkmanager" "wheel" "docker" "media" "samba" ];
        hashedPasswordFile = config.sops.secrets.zeev_password.path;
      };
      
      # Define all system users for your services
      git = { isSystemUser = true; group = "git"; };
      keycloak = { isSystemUser = true; group = "keycloak"; };
      homepage-dashboard = { isSystemUser = true; group = "homepage-dashboard"; };
      nextcloud = { isSystemUser = true; group = "nextcloud"; };
      microbin = { isSystemUser = true; group = "microbin"; };
      paperless = { isSystemUser = true; group = "paperless"; };
      miniflux = { isSystemUser = true; group = "miniflux"; };
      hass = { isSystemUser = true; group = "hass"; };
      radicale = { isSystemUser = true; group = "radicale"; };
      mosquitto = { isSystemUser = true; group = "mosquitto"; };
      grafana = { isSystemUser = true; group = "grafana"; };
      cloudflared = { isSystemUser = true; group = "cloudflared"; };
    };
  };
}
