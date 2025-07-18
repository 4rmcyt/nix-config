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

      system_keys = {
        sopsFile = ../../secrets/system.yaml;
        owner = "root";
        group = "root";
      };

      database_passwords = {
        sopsFile = ../../secrets/postgres.yaml;
        owner = "postgres";
      };
      
      homepage_secrets = {
        sopsFile = ../../secrets/homepage.yaml;
        owner = "homepage-dashboard";
      };

      cloudflare_secrets = {
        sopsFile = ../../secrets/cloudflare.yaml;
        owner = "cloudflared";
        group = "cloudflared";
      };

      tailscale_secrets = {
        sopsFile = ../../secrets/tailscale.yaml;
        owner = "tailscale";
        group = "tailscale";
      };

      keycloak_secrets = {
        sopsFile = ../../secrets/keycloak.yaml; # You will need to create this file
        owner = "keycloak";
      };
      
      grafana_secrets = {
        sopsFile = ../../secrets/grafana.yaml; # You will need to create this file
        owner = "grafana";
      };

      miniflux_secrets = {
        sopsFile = ../../secrets/miniflux.yaml; # You will need to create this file
        owner = "miniflux";
      };

      microbin_secrets = {
        sopsFile = ../../secrets/microbin.yaml; # You will need to create this file
        owner = "microbin";
      };

      paperless_secrets = {
        sopsFile = ../../secrets/paperless.yaml; # You will need to create this file
        owner = "paperless";
      };

      hass_secrets = {
        sopsFile = ../../secrets/hass.yaml; # You will need to create this file
        owner = "hass";
      };

      radicale_secrets = {
        sopsFile = ../../secrets/radicale.yaml; # You will need to create this file
        owner = "radicale";
      };

      mosquitto_secrets = {
        sopsFile = ../../secrets/mosquitto.yaml; # You will need to create this file
        owner = "mosquitto";
      };

      audiobookshelf_secrets = {
        sopsFile = ../../secrets/audiobookshelf.yaml; # You will need to create this file
        owner = "audiobookshelf";
      };

      kavita_secrets = {
        sopsFile = ../../secrets/kavita.yaml; # You will need to create this file
        owner = "kavita";
      };

      jellyfin_secrets = {
        sopsFile = ../../secrets/jellyfin.yaml; # You will need to create this file
        owner = "jellyfin";
      };

      nextcloud_secrets = {
        sopsFile = ../../secrets/nextcloud.yaml; # You will need to create this file
        owner = "nextcloud";
      };

      tplink_living_room_creds = {
        sopsFile = ../../secrets/tplink_living_room.yaml; # You will need to create this file   
      };

      tplink_office_creds = {
        sopsFile = ../../secrets/tplink_office.yaml; # You will need to create this file   
      };
      
      nextdns_secrets = {
        sopsFile = ../../secrets/nextdns.yaml; # You will need to create this file
      };
    };
  };
}