{ config, lib, pkgs, ... }:
{
  services.nixarr = {
    enable = true;
    # These two values are also the default, but you can set them to whatever
    # else you want
    # WARNING: Do _not_ set them to `/home/user/whatever`, it will not work!
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    vpn = {
      enable = true;
      wgConf = "/home/zeev/.config/nixarr/wg.conf";
    };

    transmission = {
      enable = true;
      vpn.enable = true;
      peerPort = 63998; # Set this to the port forwarded by your VPN
      extraSettings = {
        download-dir = "/home/zeev/Downloads";
        script-torrent-added-enabled = true;
        script-torrent-added-filename = "/etc/nixos/scripts/add-trackers.sh";
        blocklist-enabled = true;
        blocklist-url = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
      };
    };

    # It is possible for this module to run the *Arrs through a VPN, but it
    # is generally not recommended, as it can cause rate-limiting issues.
    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    readarr.enable = true;
    sonarr.enable = true;
    jellyseerr.enable = true;
  };
}
