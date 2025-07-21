{ config, pkgs, ... }:

{
  sops = {
    age.keyFile = "/var/lib/sops/age.key";
    defaultSopsFormat = "yaml";
    secrets = {
      # --- System & User Secrets ---
      zeev_password = { sopsFile = ../../secrets/common.yaml; neededForUsers = true; };
      ssh_host_ed25519_key = { sopsFile = ../../secrets/system.yaml; key = "ssh_host_ed25519_key"; owner = "root"; group = "root"; mode = "0600"; };
      ssh_host_rsa_key = { sopsFile = ../../secrets/system.yaml; key = "ssh_host_rsa_key"; owner = "root"; group = "root"; mode = "0600"; };
      cloudflare_tunnel_credentials = { sopsFile = ../../secrets/cloudflare_tunnel_credentials.bin; owner = "cloudflared"; group = "cloudflared"; format = "binary"; };
      cloudflare_api_key = { sopsFile = ../../secrets/cloudflare.yaml; key = "cloudflare_api_key"; };
      cloudflare_zone_id = { sopsFile = ../../secrets/cloudflare.yaml; key = "cloudflare_zone_id"; };
      tailscale_auth_key = { sopsFile = ../../secrets/tailscale.yaml; key = "tailscale_auth_key"; owner = "root"; };
      nextdns_profile_id = { sopsFile = ../../secrets/nextdns.yaml; key = "nextdns_profile_id"; };
      nextdns_api_key = { sopsFile = ../../secrets/nextdns.yaml; key = "nextdns_api_key"; };

      # --- Switch Credentials ---
      tplink_living_room_creds = { sopsFile = ../../secrets/system.yaml; key = "tplink_living_room_creds"; owner = "root"; group = "root"; };
      tplink_office_creds = { sopsFile = ../../secrets/system.yaml; key = "tplink_office_creds"; owner = "root"; group = "root"; };

      # --- Service Secrets ---
      nextcloud_admin_password = { sopsFile = ../../secrets/nextcloud.yaml; key = "nextcloud_admin_password"; owner = "nextcloud"; };
      keycloak_admin_password = { sopsFile = ../../secrets/keycloak.yaml; key = "keycloak_admin_password"; owner = "keycloak"; };
      grafana_admin_password = { sopsFile = ../../secrets/grafana.yaml; key = "grafana_admin_password"; owner = "grafana"; };
      miniflux_admin_password = { sopsFile = ../../secrets/miniflux.yaml; key = "miniflux_admin_password"; owner = "miniflux"; };
      microbin_admin_password = { sopsFile = ../../secrets/microbin.yaml; key = "microbin_admin_password"; owner = "microbin"; };
      paperless_admin_password = { sopsFile = ../../secrets/paperless.yaml; key = "paperless_admin_password"; owner = "paperless"; };
      radicale_users = { sopsFile = ../../secrets/radicale_users.txt; owner = "radicale"; group = "radicale"; mode = "0440"; format = "binary"; };

      # --- Database Passwords (from postgres.yaml) ---
      nextcloud_db_password = { sopsFile = ../../secrets/postgres.yaml; key = "nextcloud_db_password"; };
      hass_db_password = { sopsFile = ../../secrets/postgres.yaml; key = "hass_db_password"; };
      miniflux_db_password = { sopsFile = ../../secrets/postgres.yaml; key = "miniflux_db_password"; };
      keycloak_db_password = { sopsFile = ../../secrets/postgres.yaml; key = "keycloak_db_password"; };
      
      homepage_settings = {
        sopsFile = ../../secrets/homepage_settings.yaml;
        owner = "homepage-dashboard";
        format = "binary"; 
      };
      # --- Homepage Widget Credentials (from homepage.yaml) ---
      # homepage_hass_key = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_hass_key"; };
      # homepage_jellyseerr_key = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_jellyseerr_key"; };
      # homepage_lidarr_key     = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_lidarr_key"; };
      # homepage_prowlarr_key   = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_prowlarr_key"; };
      # homepage_radarr_key     = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_radarr_key"; };
      # homepage_readarr_key    = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_readarr_key"; };
      # homepage_sonarr_key     = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_sonarr_key"; };
      # homepage_bazarr_key     = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_bazarr_key"; };
      # homepage_paperless_key  = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_paperless_key"; };
      # homepage_miniflux_key   = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_miniflux_key"; };
      # homepage_nextcloud_key  = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_nextcloud_key"; };
      # homepage_tailscale_key         = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_tailscale_key"; };
      # homepage_tailscale_device_id   = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_tailscale_device_id"; };
      # homepage_cloudflared_account_id = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_cloudflared_account_id"; };
      # homepage_cloudflared_key        = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_cloudflared_key"; };
      # homepage_cloudflared_tunnel_id  = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_cloudflared_tunnel_id"; };
      # homepage_nextdns_profile_id = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_nextdns_profile_id"; };
      # homepage_nextdns_key        = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_nextdns_key"; };
      # homepage_grafana_key        = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_grafana_key"; };
      # homepage_jellyfin_key       = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_jellyfin_key"; };
      # homepage_audiobookshelf_key = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_audiobookshelf_key"; };
      # homepage_kavita_key         = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_kavita_key"; };
      # homepage_latitude  = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_latitude"; };
      # homepage_longitude = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_longitude"; };
      # homepage_grafana_admin_password = { sopsFile = ../../secrets/homepage.yaml; key = "homepage_grafana_admin_password"; };
    };
  };
}