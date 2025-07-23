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
      kavita_token_key_file = { sopsFile = ../../secrets/kavita.yaml; key = "tokenKeyFile"; owner = "kavita"; group = "kavita"; mode = "0400"; format = "binary"; };
      
      # --- Database Passwords (from postgres.yaml) ---
      hass_db_password = { sopsFile = ../../secrets/postgres.yaml; key = "hass_db_password"; };
      miniflux_db_password = { sopsFile = ../../secrets/postgres.yaml; key = "miniflux_db_password"; };
      keycloak_db_password = { sopsFile = ../../secrets/postgres.yaml; key = "keycloak_db_password"; };
      

      # --- Homepage Widget Credentials (from homepage.yaml) ---
       homepage_env = { sopsFile = ../../secrets/homepage.env; owner = "homepage"; group = "homepage";   format = "dotenv"; };
    };
  };
}