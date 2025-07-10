# In ~/src/server/services/nixarr.nix
{ config, pkgs, ... }:

{
  # The entire configuration is now correctly placed under 'services.nixarr'
  services.nixarr = {
    enable = true;
    group = "media"; # This option will now be found correctly
    mediaUsers = [ "zeev" ];
    mediaDir = "/home/zeev/media";
    stateDir = "/home/zeev/media/.state/nixarr";

    vpn = {
      enable = true;
      # This should be managed by sops-nix for security
      # wgConfFile = config.sops.secrets.nixarr_wg_conf.path;
      wgConfFile = "/home/zeev/src/wg.conf";
    };

    transmission = {
      enable = true;
      vpn.enable = true;
      peerPort = 63998;
      extraSettings = {
        "download-dir" = "/home/zeev/Downloads";
        "script-torrent-added-enabled" = true;
        "script-torrent-added-filename" = "/etc/nixos/scripts/add-trackers.sh";
        "blocklist-enabled" = true;
        "blocklist-url" = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
      };
    };

    sabnzbd = {
      enable = true;
      vpn.enable = true;
    };

    audiobookshelf.enable = true;
    jellyfin.enable = true;
    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    readarr.enable = true;
    sonarr.enable = true;
    jellyseerr.enable = true;
  };
}