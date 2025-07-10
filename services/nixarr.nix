# In ~/src/server/services/nixarr.nix
{ config, pkgs, ... }: {
  nixarr = {
    enable = true;
    # These two values are also the default, but you can set them to whatever
    # else you want
    mediaDir = "/home/zeev/media";
    stateDir = "/home/zeev/media/.state/nixarr";

    # It is possible for this module to run the *Arrs through a VPN, but it
    # is generally not recommended, as it can cause rate-limiting issues.
    vpn = {
      enable = true;
      # You can usually get this wireguard file from your VPN provider
      wgConf = "/home/zeev/src/wg.conf";
    };

    # Note: the *arrs do not need vpn.enable set, as this VPN setup does not
    # affect them unless you set `services.nixarr.vpn.all`.
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
    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    readarr.enable = true;
    sonarr.enable = true;
    jellyseerr.enable = true;
  };
}