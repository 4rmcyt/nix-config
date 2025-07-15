{ config, pkgs, ... }:

{
  users = {
    # Define all groups for your services
    groups = {
      media = {}; samba = {}; git = {}; keycloak = {};
      "homepage-dashboard" = {}; nextcloud = {}; microbin = {};
      paperless = {}; miniflux = {}; hass = {}; radicale = {};
      mosquitto = {}; grafana = {}; cloudflared = {};
      # Add groups for nixarr services
      sonarr = {}; radarr = {}; lidarr = {}; readarr = {};
      bazarr = {}; prowlarr = {}; jellyseerr = {}; transmission = {};
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
      "homepage-dashboard" = { isSystemUser = true; group = "homepage-dashboard"; };
      nextcloud = { isSystemUser = true; group = "nextcloud"; };
      microbin = { isSystemUser = true; group = "microbin"; };
      paperless = { isSystemUser = true; group = "paperless"; };
      miniflux = { isSystemUser = true; group = "miniflux"; };
      hass = { isSystemUser = true; group = "hass"; };
      radicale = { isSystemUser = true; group = "radicale"; };
      mosquitto = { isSystemUser = true; group = "mosquitto"; };
      grafana = { isSystemUser = true; group = "grafana"; };
      cloudflared = { isSystemUser = true; group = "cloudflared"; };
      
      # Add users for nixarr services
      sonarr = { isSystemUser = true; group = "media"; };
      radarr = { isSystemUser = true; group = "media"; };
      lidarr = { isSystemUser = true; group = "media"; };
      readarr = { isSystemUser = true; group = "media"; };
      bazarr = { isSystemUser = true; group = "media"; };
      prowlarr = { isSystemUser = true; group = "media"; };
      jellyseerr = { isSystemUser = true; group = "media"; };
      transmission = { isSystemUser = true; group = "media"; };
    };
  };
}
