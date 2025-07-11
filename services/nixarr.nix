# In ~/src/server/services/nixarr.nix
{ config, pkgs, ... }:
{
  nixarr = {
    enable = true;

    vpn = {
      enable = true;
      wgConf = "/home/zeev/src/wg.conf";
    };

    mediaDir = "/home/zeev/media";

    transmission = {
      enable = true;
      vpn.enable = true;
      peerPort = 63998;
      flood.enable = false;
      extraSettings = {
        download-dir = "/home/zeev/Downloads";
        script-torrent-added-enabled = true;
        script-torrent-added-filename = "/etc/nixos/scripts/add-trackers.sh";
        blocklist-enabled = true;
        blocklist-url = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
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
