{
  config,
  pkgs,
  lib,
  ...
}:

let
  user-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyieBFROVPWmH3iC2ZAE+5zofMd6mnunBzfObEwMgFx";
  user-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7QtXHGjNp8yxRIbMwb605n3fqFoq+PxOzbq6i2dEr6YDIKqajRNBHiEHjV3z7ABLpi2cfHPcw8Cgg/esD/98uGM9lKxdCev1VEubmsTmZAuDBz04p/S/yB7UBc5muHJLkzFNjlwMYP3x3JAr9if3nmrAZNh5qOrymZndJ7h9IT9WZNvvgFW2I+S/Ugi7eq5yRIDm5S7ADW/9wThfvG8ZqhMXDvvKXHJYx/O8D8th1ffN5l8pAJZkiV21zW0pu4od4iAaVM531H22FORAq6PbHAwr5u8a0jBlTqkwlo9x3O+hdKBVhW1XQfeRqg69lJtmUUFipl4viBj9Rpz+gtv4BjKL9ChCgqVLMLPe/bviRjqx3bvC2I78H0N51SvAh0QOj1ByAk3Xvj3R2qwk7LAmLgSlPoOsGpkbILhudF7KLJ/Uh2kpZI3NOcYdy9TYMws97zCvevgqw07HEEOydYpPB4+ml8Zzb+Tcw0U7yLRWMAB1VP1WE1vM0U6XQa7CRhcU=";
  zeev = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks 4rmcyt@gmail.com";
  user-keys = [
    user-ed25519
    user-rsa
    zeev
  ];

  system-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJV+/pct8PNZhUqvnflYY5auIE1zTl3sPtCfVynTnajN";
  system-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCRCKSMfoxE3uVaNDemMYYls0yoA4h4so6bVG0E+4XPa0ZEVLJYFT+tvsNdyxRmrIDLv745JCVHtv41t5qUjnafl/uBnl5dggt6W3Kkl1iZ6nyb8lgChp9egyXruEXekqTtYC0AQVjB7yC2GV5rS4R4FYY8pNYzzmmFjRT/IM6JIGn3GZubMv4GLc/xCnXZPNluNLJPxQ8oML5IjHzYFDXzDvlgB8i6ugNqE8zqIMxSFFXIrhAev41wcOE0lSjSE9gb3+HTyAmJtWCRcSyPHmKeugytNca6X3KtoU5tO1MrSlIQn8wfJkJWe/2zXueA/e4uENgS0DBVWuNXLcojYBxHFXF2OtR7R5qpVw0hcfOJkC9+EjTcRTf4MnzGfQUrDeiZerf02Dp9mvN4IBMc4nDL2h81YZcfucDd76BUkei0ppI6UbeEEFgOz1zQAggCY0I8HLZZjccK+zJzAo3JoFFbhNjX0iEWPEbcHxR3FQRDMnis0MV1gqHj8wtbWJPtqMrcAjjMu+aWfvzedEH0SDvOD6AppD2IeNVrVUJJlSk3zcX2gYfhrXEbgKG3PWxEvVnTRPk2PR+73j8ms9dONwrugKZGwMmO4c2xVWTXiI4qPfqxsBK7v7dP3f+hkx3cB34cpwtDEEBuR8hqjae4T0mJhJkcMWvDixEUxrDIJ7efkQ==";
  system-keys = [
    system-ed25519
    system-rsa
  ];

  server-keys = system-keys ++ user-keys;
in
{
  users = {
    # Define all groups for your services
    groups = {
      media = { };
      samba = { };
      git = { };
      keycloak = { };
      homepage-dashboard = { };
      nextcloud = { };
      microbin = { };
      paperless = { };
      miniflux = { };
      hass = { };
      radicale = { };
      mosquitto = { };
      grafana = { };
      cloudflared = { };
      tailscale = { };
      audiobookshelf = {};
      bazarr = {};
      jellyfin = {};
      jellyseerr = {};
      lidarr = {};
      prowlarr = {};
      radarr = {};
      readarr = {};
      sonarr = {};
      sabnzbd = {};
      transmission = {};
    };

    users = {
      zeev = {
        isNormalUser = true;
        description = "zeev";
        shell = pkgs.zsh;
        extraGroups = [
          "networkmanager"
          "wheel"
          "docker"
          "media"
          "samba"
        ];
        hashedPasswordFile = config.sops.secrets.zeev_password.path;
        openssh.authorizedKeys.keys = server-keys;
      };

      # Define all system users for your services
      git = { isSystemUser = true; group = "git"; };
      keycloak = { isSystemUser = true; group = "keycloak"; };
      homepage-dashboard = { isSystemUser = true; group = "homepage-dashboard"; };
      nextcloud = { isSystemUser = true; group = "nextcloud"; };
      microbin = { isSystemUser = true; group = "microbin"; };
      paperless = { isSystemUser = true; group = "paperless"; };
      miniflux = { isSystemUser = true; group = "miniflux"; };
      hass = { isSystemUser = true; group = "hass"; };
      radicale = { isSystemUser = true; group = "radicale"; };
      mosquitto = { isSystemUser = true; group = "mosquitto"; };
      grafana = { isSystemUser = true; group = "grafana"; };
      cloudflared = { isSystemUser = true; group = "cloudflared"; };
      tailscale = { isSystemUser = true; group = "tailscale"; };

      audiobookshelf = { isSystemUser = true; group = "audiobookshelf"; };
      bazarr = { isSystemUser = true; group = "bazarr"; };
      jellyfin = { isSystemUser = true; group = "jellyfin"; };
      jellyseerr = { isSystemUser = true; group = "jellyseerr"; };
      lidarr = { isSystemUser = true; group = "lidarr"; };
      prowlarr = { isSystemUser = true; group = "prowlarr"; };
      radarr = { isSystemUser = true; group = "radarr"; };
      readarr = { isSystemUser = true; group = "readarr"; };
      sonarr = { isSystemUser = true; group = "sonarr"; };
      sabnzbd = { isSystemUser = true; group = "sabnzbd"; };
      transmission = {
        isSystemUser = true;
        group = "transmission";
        # Correct placement for extraGroups specific to 'transmission' user
        extraGroups = [ "users" "media" ]; # Added "media" as it might need access to /data/media paths
      };
    };
  };

  # Correct placement for systemd.tmpfiles.rules - it's a top-level option.
  systemd.tmpfiles.rules = [
    # Ensure /data exists and is owned by zeev. It seems you manage /data manually,
    # but tmpfiles can ensure it's always there with correct permissions.
    "d /data 0755 zeev root -" # Current: drwxr-xr-x 1 zeev root
    "d /data/Downloads 0775 zeev users -" # Current: drwxr-xr-x 1 zeev users. Give group write access.

    "d /data/media 0775 root media -" # Current: drwxrwxr-x 1 root media. Keep this.
    "d /data/media/library 0775 zeev media -" # Current: drwxrwxr-x 1 zeev media. Keep this.
    "d /data/media/torrents 0775 zeev media -" # Current: drwxr-xr-x 1 zeev media. Give group write.
    "d /data/media/usenet 0775 zeev media -" # Current: drwxr-xr-x 1 zeev media. Give group write.

    # /data/media/.state is the root of the problem for CHDIR errors.
    # It's currently `zeev:root` and `drwxr-xr-x`. This needs to be more permissive.
    # I recommend making it `root:media` with `0775` so any service in `media` group can create subdirectories.
    "d /data/media/.state 0775 root media -"
    "d /data/media/.state/nixarr 0775 root media -"

    # Specific Nixarr Service Directories (users/groups now explicitly defined)
    "d /data/media/.state/nixarr/audiobookshelf 0755 audiobookshelf audiobookshelf -"
    "d /data/media/.state/nixarr/bazarr 0755 bazarr bazarr -"
    "d /data/media/.state/nixarr/jellyfin 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/data 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/config 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/cache 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/log 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyseerr 0755 jellyseerr jellyseerr -"
    "d /data/media/.state/nixarr/lidarr 0755 lidarr lidarr -"
    "d /data/media/.state/nixarr/prowlarr 0755 prowlarr prowlarr -"
    "d /data/media/.state/nixarr/radarr 0755 radarr radarr -"
    "d /data/media/.state/nixarr/readarr 0755 readarr readarr -"
    "d /data/media/.state/nixarr/sonarr 0755 sonarr sonarr -"

    "d /var/lib/miniflux 0750 miniflux miniflux -" # Common location for miniflux data/DB

    "d /data/media/.state/nixarr/sabnzbd 0755 sabnzbd sabnzbd -"
    # Add more specific SABnzbd subdirectories if needed by the service config, e.g.:
    # "d /data/media/.state/nixarr/sabnzbd/downloads/complete 0775 sabnzbd media -"
    # "d /data/media/.state/nixarr/sabnzbd/downloads/incomplete 0775 sabnzbd media -"
    # "d /data/media/.state/nixarr/sabnzbd/config 0755 sabnzbd sabnzbd -"

    "d /var/lib/transmission 0755 transmission transmission -" # Transmission's internal state/config

    # For `/data/.secret`:
    # `0700 zeev media` means only `zeev` (owner) has access. `media` group has no access.
    # If a service (running as a system user, possibly in `media` group) needs to read `wg.conf` in there,
    # then the `.secret` directory or the `wg.conf` file itself needs to be group-readable (e.g., 0750 or 0440).
    # Since VPN services are typically run by their own system users or root,
    # and the error wasn't about VPN, we'll keep it as 0700 for now.
    "d /data/.secret 0700 zeev media -"
  ];
}
