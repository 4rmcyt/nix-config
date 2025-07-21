{ config, pkgs, lib, ... }:

{
  sops = {
    age.keyFile = "/var/lib/sops/age.key";
    defaultSopsFormat = "yaml";
    secrets = {

      cloudflare_api_key = {
        sopsFile = ../../secrets/cloudflare.yaml;
        key = "cloudflare_api_key";
      };
      nextcloud_admin_password = {
        sopsFile = ../../secrets/nextcloud.yaml;
        key = "nextcloud_admin_password";
        owner = "nextcloud";
      };
      nextcloud_db_password = {
        sopsFile = ../../secrets/postgres.yaml;
        key = "nextcloud_db_password";
        owner = "nextcloud";
      };
      ssh_host_ed25519_key = {
        sopsFile = ../../secrets/system.yaml;
        key = "ssh_host_ed25519_key";
        owner = "root"; group = "root"; mode = "0600";
      };
      ssh_host_rsa_key = {
        sopsFile = ../../secrets/system.yaml;
        key = "ssh_host_rsa_key";
        owner = "root"; group = "root"; mode = "0600";
      };
      tailscale_auth_key = {
        sopsFile = ../../secrets/tailscale.yaml;
        key = "tailscale_auth_key";
        owner = "root";
      };
      zeev_password = {
        sopsFile = ../../secrets/common.yaml;
        key = "zeev_password";
        neededForUsers = true;
      };


      cloudflare_tunnel_credentials = {
        sopsFile = ../../secrets/cloudflare-creds.json;
        owner = "cloudflared";
      };

 
      # audiobookshelf_secrets = { sopsFile = ../../secrets/audiobookshelf.yaml; owner = "audiobookshelf"; };
      cloudflare_secrets = { sopsFile = ../../secrets/cloudflare.yaml; };
      database_passwords = { sopsFile = ../../secrets/postgres.yaml; owner = "postgres"; };
      grafana_secrets = { sopsFile = ../../secrets/grafana.yaml; owner = "grafana"; };
      hass_secrets = { sopsFile = ../../secrets/hass.yaml; owner = "homeassistant"; };
      homepage_secrets = { sopsFile = ../../secrets/homepage.yaml; owner = "homepage-dashboard"; };
      # jellyfin_secrets = { sopsFile = ../../secrets/jellyfin.yaml; owner = "jellyfin"; };
      # kavita_secrets = { sopsFile = ../../secrets/kavita.yaml; owner = "kavita"; };
      keycloak_secrets = { sopsFile = ../../secrets/keycloak.yaml; owner = "keycloak"; };
      microbin_secrets = { sopsFile = ../../secrets/microbin.yaml; owner = "microbin"; };
      miniflux_secrets = { sopsFile = ../../secrets/miniflux.yaml; owner = "miniflux"; };
      # mosquitto_secrets = { sopsFile = ../../secrets/mosquitto.yaml; owner = "mosquitto"; };
      nextcloud_secrets = { sopsFile = ../../secrets/nextcloud.yaml; owner = "nextcloud"; };
      nextdns_secrets = { sopsFile = ../../secrets/nextdns.yaml; };
      paperless_secrets = { sopsFile = ../../secrets/paperless.yaml; owner = "paperless"; };
      radicale_secrets = { sopsFile = ../../secrets/radicale.yaml; owner = "radicale"; };
      system_keys = { sopsFile = ../../secrets/system.yaml; owner = "root"; group = "root"; };
      tailscale_secrets = { sopsFile = ../../secrets/tailscale.yaml; owner = "tailscale"; group = "tailscale"; };
      tplink_living_room_creds = { sopsFile = ../../secrets/system.yaml; owner = "root"; };
      tplink_office_creds = { sopsFile = ../../secrets/system.yaml; owner = "root"; };
    };
  };
}
