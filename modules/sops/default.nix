{ config, pkgs, ... }:

{
 sops = {
    age.keyFile = "/var/lib/sops/age.key";
    defaultSopsFormat = "yaml";
    secrets = {
       # User Passwords
      zeev_password = {
        sopsFile = ../../secrets/common.yaml;
        neededForUsers = true;
      };

      ssh_host_ed25519_key = {
        sopsFile = ../../secrets/system.yaml;
        owner = "root";
        group = "root";
        mode = "0600";
      };
      ssh_host_rsa_key = {
        sopsFile = ../../secrets/system.yaml;
        owner = "root";
        group = "root";
        mode = "0600";
      };

      system_keys = {
        sopsFile = ../../secrets/system.yaml;
        owner = "root";
        group = "root";
      };

      database_passwords = {
        sopsFile = ../../secrets/postgres.yaml;
        owner = "postgres";
      };
      
      nextcloud_db_password = {
        sopsFile = ../../secrets/postgres.yaml; # Still reads from the main postgres file
        key = "nextcloud_db_password";        # But only extracts this specific key
        owner = "nextcloud";
      };

      nextcloud_admin_password = {
        sopsFile = ../../secrets/nextcloud.yaml; # Reads from the nextcloud secrets file
        key = "nextcloud_admin_password";     # But only extracts this specific key
        owner = "nextcloud";
      };
      
      tailscale_auth_key = {
        sopsFile = ../../secrets/tailscale.yaml;
        key = "tailscale_auth_key";
        # The autoconnect service runs as root
        owner = "root";
      };

      homepage_secrets = {
        sopsFile = ../../secrets/homepage.yaml;
        owner = "homepage-dashboard";
      };

      cloudflare_tunnel_credentials = {
        sopsFile = ../../secrets/cloudflare-creds.json;
        owner = "cloudflared";
        group = "cloudflared";
      };

      cloudflare_secrets = {
        sopsFile = ../../secrets/cloudflare.yaml;
      };

      cloudflare_api_key = {
        sopsFile = ../../secrets/cloudflare.yaml;
        key = "cloudflare_api_key";
      };
      
      tailscale_secrets = {
        sopsFile = ../../secrets/tailscale.yaml;
        owner = "tailscale";
        group = "tailscale";
      };

      keycloak_secrets = {
        sopsFile = ../../secrets/keycloak.yaml;
        owner = "keycloak";
      };
      
      grafana_secrets = {
        sopsFile = ../../secrets/grafana.yaml;
        owner = "grafana";
      };

      miniflux_secrets = {
        sopsFile = ../../secrets/miniflux.yaml;
        owner = "miniflux";
      };

      microbin_secrets = {
        sopsFile = ../../secrets/microbin.yaml;
        owner = "microbin";
      };

      paperless_secrets = {
        sopsFile = ../../secrets/paperless.yaml;
        owner = "paperless";
      };

      hass_secrets = {
        sopsFile = ../../secrets/hass.yaml;
        owner = "home-assistant"; # Corrected owner
      };

      radicale_secrets = {
        sopsFile = ../../secrets/radicale.yaml;
        owner = "radicale";
      };

      mosquitto_secrets = {
        sopsFile = ../../secrets/mosquitto.yaml;
        owner = "mosquitto";
      };

      audiobookshelf_secrets = {
        sopsFile = ../../secrets/audiobookshelf.yaml;
        owner = "audiobookshelf";
      };

      kavita_secrets = {
        sopsFile = ../../secrets/kavita.yaml;
        owner = "kavita";
      };

      jellyfin_secrets = {
        sopsFile = ../../secrets/jellyfin.yaml;
        owner = "jellyfin";
      };

      nextcloud_secrets = {
        sopsFile = ../../secrets/nextcloud.yaml;
        owner = "nextcloud";
      };
      
      nextdns_secrets = {
        sopsFile = ../../secrets/nextdns.yaml;
      };
    };
  };
}
