{ config, pkgs, ... }:

{
  # Central VPN configuration
  services.nixarr.vpn = {
    enable = true;
    wgConfFile = "/home/zeev/src/wg.conf";
  };

  # Each application is its own service, with its own dataDir and group
  services.transmission = {
    enable = true;
    vpn.enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/transmission";
    settings = {
      peer-port = 63998;
      download-dir = "/home/zeev/downloads"; # Note: Transmission has its own download setting
    };
  };

  services.sabnzbd = {
    enable = true;
    vpn.enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/sabnzbd";
  };

  services.audiobookshelf = {
    enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/audiobookshelf";
  };

  services.jellyfin = {
    enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/jellyfin";
  };

  services.bazarr = {
    enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/bazarr";
  };

  services.lidarr = {
    enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/lidarr";
  };

  services.prowlarr = {
    enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/prowlarr";
  };

  services.radarr = {
    enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/radarr";
  };

  services.readarr = {
    enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/readarr";
  };

  services.sonarr = {
    enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/sonarr";
  };

  services.jellyseerr = {
    enable = true;
    group = "media";
    dataDir = "/home/zeev/media/.state/nixarr/jellyseerr";
  };
}