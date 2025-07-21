{ config, pkgs, lib, ... }:

{
  # 1. CONFIGURE THE SERVICE LAYOUT
  # This section only contains the dashboard's visual layout.
  # ALL secret and environment variable settings have been removed from here.
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    # ... all of your 'services', 'widgets', and 'bookmarks' sections go here,
    # with the corrected `{{HOMEPAGE_VAR_...}}` syntax from the previous step ...
    # For example:
    services = [
      {
        "Arrs" = [
          {
            "Radarr" = {
              icon = "radarr.png";
              href = "https://movies.labhome.work/";
              widgets = [{
                type = "radarr";
                url = "http://localhost:7878";
                key = "{{HOMEPAGE_VAR_RADARR_KEY}}"; # Ensure this syntax is correct
              }];
            };
          }
          # ... etc
        ];
      }
    ];
  };

  # 2. CONFIGURE THE UNDERLYING SYSTEMD SERVICE
  # Because the NixOS module is so limited, we configure systemd directly.
  # This is the guaranteed way to set the environment variables.
  systemd.services.homepage-dashboard.serviceConfig = {
    # Set non-secret environment variables here
    Environment = [
      "HOMEPAGE_ALLOWED_HOSTS=localhost,127.0.0.1,192.168.1.165,home.labhome.work"
    ];

    # Use LoadCredential to securely load each secret from its file
    # into an environment variable.
    LoadCredential = [
      "HOMEPAGE_VAR_JELLYSEERR_KEY:${config.sops.secrets.homepage_jellyseerr_key.path}"
      "HOMEPAGE_VAR_LIDARR_KEY:${config.sops.secrets.homepage_lidarr_key.path}"
      "HOMEPAGE_VAR_PROWLARR_KEY:${config.sops.secrets.homepage_prowlarr_key.path}"
      "HOMEPAGE_VAR_RADARR_KEY:${config.sops.secrets.homepage_radarr_key.path}"
      "HOMEPAGE_VAR_READARR_KEY:${config.sops.secrets.homepage_readarr_key.path}"
      "HOMEPAGE_VAR_SONARR_KEY:${config.sops.secrets.homepage_sonarr_key.path}"
      "HOMEPAGE_VAR_BAZARR_KEY:${config.sops.secrets.homepage_bazarr_key.path}"
      "HOMEPAGE_VAR_PAPERLESS_KEY:${config.sops.secrets.homepage_paperless_key.path}"
      "HOMEPAGE_VAR_MINIFLUX_KEY:${config.sops.secrets.homepage_miniflux_key.path}"
      "HOMEPAGE_VAR_NEXTCLOUD_KEY:${config.sops.secrets.homepage_nextcloud_key.path}"
      "HOMEPAGE_VAR_TAILSCALE_KEY:${config.sops.secrets.homepage_tailscale_key.path}"
      "HOMEPAGE_VAR_TAILSCALE_DEVICE_ID:${config.sops.secrets.homepage_tailscale_device_id.path}"
      "HOMEPAGE_VAR_CLOUDFLARED_ACCOUNT_ID:${config.sops.secrets.homepage_cloudflared_account_id.path}"
      "HOMEPAGE_VAR_CLOUDFLARED_KEY:${config.sops.secrets.homepage_cloudflared_key.path}"
      "HOMEPAGE_VAR_CLOUDFLARED_TUNNEL_ID:${config.sops.secrets.homepage_cloudflared_tunnel_id.path}"
      "HOMEPAGE_VAR_NEXTDNS_PROFILE_ID:${config.sops.secrets.homepage_nextdns_profile_id.path}"
      "HOMEPAGE_VAR_NEXTDNS_KEY:${config.sops.secrets.homepage_nextdns_key.path}"
      "HOMEPAGE_VAR_GRAFANA_KEY:${config.sops.secrets.homepage_grafana_key.path}"
      "HOMEPAGE_VAR_JELLYFIN_KEY:${config.sops.secrets.homepage_jellyfin_key.path}"
      "HOMEPAGE_VAR_AUDIOBOOKSHELF_KEY:${config.sops.secrets.homepage_audiobookshelf_key.path}"
      "HOMEPAGE_VAR_KAVITA_KEY:${config.sops.secrets.homepage_kavita_key.path}"
      "HOMEPAGE_VAR_LATITUDE:${config.sops.secrets.homepage_latitude.path}"
      "HOMEPAGE_VAR_LONGITUDE:${config.sops.secrets.homepage_longitude.path}"
      "HOMEPAGE_VAR_GRAFANA_ADMIN_PASSWORD:${config.sops.secrets.homepage_grafana_admin_password.path}"
      "HOMEPAGE_VAR_HASS_KEY:${config.sops.secrets.homepage_hass.path}"
    ];
  };
}