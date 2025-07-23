{ config, pkgs, ... }:

{
  sops = {
    age.keyFile = "/var/lib/sops/age.key";
    defaultSopsFormat = "yaml";
    secrets = {
      # --- System & User Secrets ---
      zeev_password = { sopsFile = ../../secrets/common.yaml; neededForUsers = true; };
      zeev_gpg_key = { sopsFile = ../../secrets/system.yaml; key = "gpg"; owner = "zeev"; mode = "0400"; };
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
      keycloak_admin_password = { sopsFile = ../../secrets/keycloak.yaml; key = "keycloak_admin_password"; owner = "keycloak"; };
      grafana_admin_password = { sopsFile = ../../secrets/grafana.yaml; key = "grafana_admin_password"; owner = "grafana"; };
      miniflux_admin_password = { sopsFile = ../../secrets/miniflux.yaml; key = "miniflux_admin_password"; owner = "miniflux"; };
      microbin_admin_password = { sopsFile = ../../secrets/microbin.yaml; key = "microbin_admin_password"; owner = "microbin"; };
      paperless_admin_password = { sopsFile = ../../secrets/paperless.yaml; key = "paperless_admin_password"; owner = "paperless"; };
      radicale_users = { sopsFile = ../../secrets/radicale_users.txt; owner = "radicale"; group = "radicale"; mode = "0440"; format = "binary"; };
      kavita_token_key_file = { sopsFile = ../../secrets/kavita.yaml; key = "tokenKeyFile"; owner = "kavita"; group = "kavita"; };
      
      # --- Database Passwords (from postgres.yaml) ---
      hass_db_password = { sopsFile = ../../secrets/postgres.yaml; key = "hass_db_password"; };
      miniflux_db_password = { sopsFile = ../../secrets/postgres.yaml; key = "miniflux_db_password"; };
      keycloak_db_password = { sopsFile = ../../secrets/postgres.yaml; key = "keycloak_db_password"; };
      

      # --- Homepage Widget Credentials (from homepage.yaml) ---
      homepage_jellyseerr_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_JELLYSEERR_KEY"; };
      homepage_lidarr_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_LIDARR_KEY"; };
      homepage_prowlarr_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_PROWLARR_KEY"; };
      homepage_radarr_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_RADARR_KEY"; };
      homepage_readarr_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_READARR_KEY"; };
      homepage_readarr_audiobooks_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_READARR_AUDIOBOOKS_KEY"; };
      homepage_sonarr_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_SONARR_KEY"; };
      homepage_bazarr_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_BAZARR_KEY"; };
      homepage_paperless_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_PAPERLESS_KEY"; };
      homepage_tailscale_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_TAILSCALE_KEY"; };
      homepage_tailscale_device_id = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_TAILSCALE_DEVICE_ID"; };
      homepage_cloudflared_account_id = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_CLOUDFLARED_ACCOUNT_ID"; };
      homepage_cloudflared_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_CLOUDFLARED_KEY"; };
      homepage_cloudflared_tunnel_id = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_CLOUDFLARED_TUNNEL_ID"; };
      homepage_jellyfin_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_JELLYFIN_KEY"; };
      homepage_audiobookshelf_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_AUDIOBOOKSHELF_KEY"; };
      homepage_kavita_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_KAVITA_KEY"; };
      homepage_latitude = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_LATITUDE"; };
      homepage_longitude = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_LONGITUDE"; };
      homepage_hass_key = { sopsFile = ../../secrets/homepage.yaml; key = "HOMEPAGE_VAR_HASS_KEY"; };
    };
  };
}