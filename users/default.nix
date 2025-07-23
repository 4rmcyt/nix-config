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
      microbin = { };
      paperless = { };
      miniflux = { };
      hass = { };
      radicale = { };
      mosquitto = { };
      grafana = { };
      cloudflared = { };
      tailscale = { };
    # Groups for nixarr services - keep them defined here
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
      paperless = { isSystemUser = true; group = "paperless"; };
      miniflux = { isSystemUser = true; group = "miniflux"; };
      hass = { isSystemUser = true; group = "hass"; };
      radicale = { isSystemUser = true; group = "radicale"; };
      mosquitto = { isSystemUser = true; group = "mosquitto"; };
      grafana = { isSystemUser = true; group = "grafana"; };
      cloudflared = { isSystemUser = true; group = "cloudflared"; };
      tailscale = { isSystemUser = true; group = "tailscale"; };

      microbin = {
        isSystemUser = true;
        group = "microbin"; # Keep its primary group
        extraGroups = [ "users" "media" ]; # Add to both 'users' and 'media' groups
      };
      # Samba:
      samba = {
        isSystemUser = true;
        group = "samba"; # Keep its primary group
        extraGroups = [ "users" "media" ]; # Add to both 'users' and 'media' groups
      };

      audiobookshelf = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
      bazarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
      jellyfin = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
      jellyseerr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
      lidarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
      prowlarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
      radarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
      readarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
      sonarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
      sabnzbd = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
      transmission = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
    };
  };

  # Correct placement for systemd.tmpfiles.rules - it's a top-level option.
  systemd.tmpfiles.rules = [
    # Top-level /data directory and its children that are shared
    # Ensure /data is writable by root and the 'media' group
    "d /data 0775 root media -"
    "d /data/media/movies 0775 zeev media -"
    "d /data/media/audiobooks 0775 zeev media -"
    "d /data/media/music 0775 zeev media -"
    "d /data/media/shows 0775 zeev media -"
    "d /data/media/books 0775 zeev media -"
    "d /data/media/comics 0775 zeev media -"
    "d /data/media/manga 0775 zeev media -"
    "d /data/media/torrents 0775 zeev media -"
    "d /data/media/usenet 0775 zeev media -"
    "d /data/Downloads 0775 zeev users -"

    # /data/media and its subdirectories (library, torrents, usenet)
    # should be writable by root/zeev and the 'media' group
    "d /data/media 0775 root media -"
    "d /data/media/library 0775 zeev media -"
    "d /data/media/torrents 0775 zeev media -"
    "d /data/media/usenet 0775 zeev media -"

    # /data/media/.state and /data/media/.state/nixarr need to be writable by root and the 'media' group
    "d /data/media/.state 0775 root media -"
    "d /data/media/.state/nixarr 0775 root media -"

    # Individual service state directories under nixarr (keep as 0755 for isolation)
    "d /data/media/.state/nixarr/audiobookshelf 0775 audiobookshelf audiobookshelf -"
    "d /data/media/.state/nixarr/bazarr 0775 bazarr bazarr -"
    "d /data/media/.state/nixarr/jellyfin 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/data 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/config 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/cache 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/log 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyseerr 0775 jellyseerr jellyseerr -"
    "d /data/media/.state/nixarr/lidarr 0775 lidarr lidarr -"
    "d /data/media/.state/nixarr/prowlarr 0775 prowlarr prowlarr -"
    "d /data/media/.state/nixarr/radarr 0775 radarr radarr -"
    "d /data/media/.state/nixarr/readarr 0775 readarr readarr -"
    "d /data/media/.state/nixarr/sonarr 0775 sonarr sonarr -"
    
    "d /data/media/.state/nixarr/jellyseerr/db 0775 jellyseerr jellyseerr -" # New line for 'db'
    "d /data/media/.state/nixarr/jellyseerr/logs 0755 jellyseerr jellyseerr -" # For 'logs'

    # Specific directories for other services
    "d /var/lib/miniflux 0775 miniflux miniflux -" # Standard data dir for miniflux
    "d /var/lib/microbin 0775 microbin microbin -" # Standard data dir for microbin

    "d /data/media/.state/nixarr/sabnzbd 0775 sabnzbd sabnzbd -"
    "d /var/lib/transmission 0775 transmission transmission -" # Standard data dir for transmission

    "d /data/.secret 0700 zeev media -" # Keep tight permissions for secrets directory
  ];
}
