# In ~/src/server/services/nixarr.nix
{ config, pkgs, ... }:
{
  nixarr = {
  services.sabnzbd = {
    enable = true;
    vpn.enable = true;
  };
  
  services.audiobookshelf = {
    enable = true;
    user = "zeev";
    group = "media";
  };
  
  services.jellyfin = {
    enable = true;
    user = "zeev";
    group = "media";
  };
  
  services.bazarr = {
    enable = true;
    user = "zeev";
    group = "media";
  };
  
  services.lidarr = {
    enable = true;
    user = "zeev";
    group = "media";
  };
  
  services.prowlarr = {
    enable = true;
    user = "zeev";
    group = "media";
  };
  
  services.radarr = {
    enable = true;
    user = "zeev";
    group = "media";
  };
  
  services.readarr = {
    enable = true;
    user = "zeev";
    group = "media";
  };
  
  services.sonarr = {
    enable = true;
    user = "zeev";
    group = "media";
  };
  
  services.jellyseerr = {
    enable = true;
    user = "zeev";
    group = "media";
  };
};
    enable = true;
    mediaUsers = [ 
      "zeev"
      "transmission"
      "sabnzbd"
      "audiobookshelf"
      "jellyfin"
      "bazarr"
      "lidarr"
      "prowlarr"
      "radarr"
      "readarr"
      "sonarr"
      "jellyseerr"  
       ];
    mediaDir = "/home/zeev/media";
    stateDir = "/home/zeev/media/.state/nixarr";

    vpn = {
      enable = true;
      wgConf = "/home/zeev/src/wg.conf";
    };

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
