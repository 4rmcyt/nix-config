{ config, pkgs, ... }:

{
 sops = {
    defaultSopsFile = ../secrets.yaml;
    age.keyFile = "/etc/sops/age.key";
    secrets = {
      zeev_password.neededForUsers = true;

    ssh_host_ed25519_key = { owner = "root"; group = "root"; mode = "0600"; };
    ssh_host_rsa_key     = { owner = "root"; group = "root"; mode = "0600"; };

    # Passwords for databases used by postgres
    miniflux_db_password = { owner = config.services.postgresql.package.user; };
    hass_db_password          = { owner = config.services.postgresql.package.user; };
    keycloak_db_password       = { owner = config.services.postgresql.package.user; };
    nextcloud_db_password      = { owner = config.services.postgresql.package.user; };

    # Passwords for applications, owned by the application's user
    nextcloud_admin_password = { owner = "nextcloud"; };
    microbin_admin_password  = { owner = "microbin"; };
    paperless_admin_password = { owner = "paperless"; };
    miniflux_admin_password = { owner = "miniflux"; };
    hass_admin_password     = { owner = "hass"; };
    radicale_htpasswd = { owner = "radicale"; };
    keycloak_admin_password = { owner = "keycloak"; };
    mosquitto_iotdevice_password = { owner = "mosquitto"; };
    grafana_admin_password = { owner = "grafana"; };

    cloudflare_tunnel_credentials   = { owner = "cloudflared"; group = "cloudflared"; mode = "0600"; };
    cloudflare_tunnel_id = { owner = "cloudflared"; group = "cloudflared"; mode = "0600"; };

    tailscale_auth_key = {};
    tailscale_ip  = {};
    

    # You need to set the owner for these based on which service uses them.
    # For example, if Home Assistant sends notifications: owner = "hass";
    telegram_bot_token = { };
    telegram_chat_id  = { };

    yubikey_client_id = { };
    yubikey_secret_key = { };
    webauthn_relying_party_name = { };
    webauthn_relying_party_id = { };
    cloudflare_api_key = {};
    cloudflare_zone_id = {};

    #arr
    sonarr_key = {  };
    radarr_key = { };
    prowlarr_key = {  };
    jellyseerr_key = {  };
    bazarr_key = {  };
    lidarr_key = { };
    readarr_key = {  };
    
    # Homepage widgets
    homepage_tailscale_key = { owner  = "homepage-dashboard"; };
    homepage_tailscale_device_id = { owner = "homepage-dashboard"; };
    homepage_paperless_key = { owner = "homepage-dashboard"; };
    homepage_miniflux_key = { owner = "homepage-dashboard"; };
    homepage_nextcloud_key = { owner = "homepage-dashboard"; };
    homepage_microbin_key = { owner = "homepage-dashboard"; };
    homepage_keycloak_key = { owner = "homepage-dashboard"; };
    homepage_hass_key = { owner = "homepage-dashboard"; };
    homepage_radicale_key = { owner = "homepage-dashboard"; };
    homepage_kavita_key = { owner = "homepage-dashboard"; };
    homepage_cloudflared_key = { owner = "homepage-dashboard"; };
    homepage_jellyfin_key = { owner = "homepage-dashboard"; };
    homepage_audiobookshelf_key = { owner = "homepage-dashboard"; };
    homepage_grafana_key = { owner = "homepage-dashboard"; };
    homepage_nextdns_key = { owner = "homepage-dashboard"; };
    homepage_nextdns_profile_id = { owner = "homepage-dashboard"; };
    };
  };
}