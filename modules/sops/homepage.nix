{ config, ... }:

let
  # Helper function to create a secret owned by the homepage-dashboard user
  mkSecret = name: {
    key = "HOMEPAGE_VAR_${name}";
    owner = homepage-dashboard;
    group = homepage-dashboard;
  };
in
{
  sops.secrets = {
    homepage_jellyfin_key = mkSecret "JELLYFIN_KEY";
    homepage_audiobookshelf_key = mkSecret "AUDIOBOOKSHELF_KEY";
    homepage_sonarr_key = mkSecret "SONARR_KEY";
    homepage_radarr_key = mkSecret "RADARR_KEY";
    homepage_prowlarr_key = mkSecret "PROWLARR_KEY";
    homepage_bazarr_key = mkSecret "BAZARR_KEY";
    homepage_jellyseerr_key = mkSecret "JELLYSEERR_KEY";
    homepage_lidarr_key = mkSecret "LIDARR_KEY";
    homepage_readarr_key = mkSecret "READARR_KEY";
    homepage_readarr_audiobooks_key = mkSecret "READARR_AUDIOBOOKS_KEY";
    homepage_paperless_key = mkSecret "PAPERLESS_KEY";
    homepage_kavita_key = mkSecret "KAVITA_KEY";
    # Note: grafana_admin_password is created separately below
    homepage_hass_key = mkSecret "HASS_KEY";
    homepage_tailscale_device_id = mkSecret "TAILSCALE_DEVICE_ID";
    homepage_tailscale_key = mkSecret "TAILSCALE_KEY";
    homepage_cloudflared_account_id = mkSecret "CLOUDFLARED_ACCOUNT_ID";
    homepage_cloudflared_tunnel_id = mkSecret "CLOUDFLARED_TUNNEL_ID";
    homepage_cloudflared_key = mkSecret "CLOUDFLARED_KEY";
    homepage_latitude = mkSecret "LATITUDE";
    homepage_longitude = mkSecret "LONGITUDE";

    # This one doesn't fit the pattern, so we define it manually
    grafana_admin_password = {
      key = "HOMEPAGE_VAR_GRAFANA_ADMIN_PASSWORD";
      owner = config.services.homepage-dashboard.user;
      group = config.services.homepage-dashboard.group;
    };
  };

  # All the homepage secrets are in a single YAML file
  sops.secrets."homepage_jellyfin_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_audiobookshelf_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_sonarr_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_radarr_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_prowlarr_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_bazarr_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_jellyseerr_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_lidarr_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_readarr_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_readarr_audiobooks_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_paperless_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_kavita_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."grafana_admin_password".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_hass_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_tailscale_device_id".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_tailscale_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_cloudflared_account_id".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_cloudflared_tunnel_id".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_cloudflared_key".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_latitude".sopsFile = ../secrets/homepage.yaml;
  sops.secrets."homepage_longitude".sopsFile = ../secrets/homepage.yaml;
}