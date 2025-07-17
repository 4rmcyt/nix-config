{ config, pkgs, ... }:

{
 sops = {
    age.keyFile = "/etc/ssh/ssh_host_ed25519_key";
    secrets = {
       # User Passwords
      zeev_password.neededForUsers = true;

      # System SSH Host Keys
      "ssh_host_ed25519_key" = { owner = "root"; group = "root"; mode = "0600"; };
      "ssh_host_rsa_key"     = { owner = "root"; group = "root"; mode = "0600"; };

      # Database Passwords
      "miniflux_db_password"  = { owner = "postgres"; };
      "hass_db_password"      = { owner = "postgres"; };
      "keycloak_db_password"  = { owner = "postgres"; };
      "nextcloud_db_password" = { owner = "postgres"; };

      # Application Admin Passwords
      "nextcloud_admin_password" = { owner = "nextcloud"; };
      "microbin_admin_password"  = { owner = "microbin"; };
      "paperless_admin_password" = { owner = "paperless"; };
      "miniflux_admin_password"  = { owner = "miniflux"; };
      "radicale_htpasswd"        = { owner = "radicale"; };
      "keycloak_admin_password"  = { owner = "keycloak"; };
      "mosquitto_iotdevice_password" = { owner = "mosquitto"; };
      "grafana_admin_password"   = { owner = "grafana"; };

      # Cloudflare Credentials
      "cloudflare_tunnel_credentials" = { owner = "cloudflared"; group = "cloudflared"; };
      "cloudflare_api_key"     = {};
      "cloudflare_zone_id"     = {};

      # Other root-owned secrets
      "tailscale_auth_key" = {};
      "tailscale_ip"       = {};
      "telegram_bot_token" = {};
      "telegram_chat_id"   = {};
      "yubikey_client_id"  = {};
      "yubikey_secret_key" = {};
      "webauthn_relying_party_name" = {};
      "webauthn_relying_party_id"   = {};
      
      "nextdns_api_key" = { owner = "root"; };
      "nextdns_profile_id" = { owner = "root"; };

      "tplink_living_room_creds" = { owner = "root"; };
      "tplink_office_creds" = { owner = "root"; };

      
      # Nixarr API Keys
      "sonarr_key"     = { owner = "homepage-dashboard"; };
      "radarr_key"     = { owner = "homepage-dashboard"; };
      "prowlarr_key"   = { owner = "homepage-dashboard"; };
      "jellyseerr_key" = { owner = "homepage-dashboard"; };
      "bazarr_key"     = { owner = "homepage-dashboard"; };
      "lidarr_key"     = { owner = "homepage-dashboard"; };
      "readarr_key"    = { owner = "homepage-dashboard"; };
      
      # Other Homepage Widget Keys
      "homepage_tailscale_key"          = { owner = "homepage-dashboard"; };
      "homepage_tailscale_device_id"    = { owner = "homepage-dashboard"; };
      "homepage_paperless_key"          = { owner = "homepage-dashboard"; };
      "homepage_miniflux_key"           = { owner = "homepage-dashboard"; };
      "homepage_nextcloud_key"          = { owner = "homepage-dashboard"; };
      "homepage_hass_key"               = { owner = "homepage-dashboard"; };
      "homepage_kavita_key"             = { owner = "homepage-dashboard"; };
      "homepage_cloudflared_key"        = { owner = "homepage-dashboard"; };
      "homepage_cloudflared_account_id" = { owner = "homepage-dashboard"; };
      "homepage_cloudflared_tunnel_id"  = { owner = "homepage-dashboard"; };
      "homepage_jellyfin_key"           = { owner = "homepage-dashboard"; };
      "homepage_audiobookshelf_key"     = { owner = "homepage-dashboard"; };
      "homepage_grafana_key"            = { owner = "homepage-dashboard"; };
      "homepage_nextdns_key"            = { owner = "homepage-dashboard"; };
      "homepage_nextdns_profile_id"     = { owner = "homepage-dashboard"; };
    };
  };
}