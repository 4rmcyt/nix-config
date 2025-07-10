# In ~/src/server/services/nixarr.nix
{ config, pkgs, ... }: {
  nixarr = {
    enable = true;
    mediaUsers = "zeev";
    mediaDir = "/home/zeev/media";
    stateDir = "/home/zeev/media/.state/nixarr";

    # It is possible for this module to run the *Arrs through a VPN, but it
    # is generally not recommended, as it can cause rate-limiting issues.
    vpn = {
      enable = true;
      wgConf = "/home/zeev/src/wg.conf";
    };


    transmission = {
        enable = true;
        vpn.enable = true;
        peerPort = 63998;
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
      #openFirewall = true;
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