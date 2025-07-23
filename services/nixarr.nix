# In ~/src/server/services/nixarr.nix
{ config, pkgs, ... }:
{
   environment.etc."nixos/scripts/add-trackers.sh" = {
    mode = "0755";
    text = ''
      #!${pkgs.stdenv.shell}

      TRANSMISSION_REMOTE="${pkgs.transmission}/bin/transmission-remote"
      WGET="${pkgs.wget}/bin/wget"
      SED="${pkgs.gnused}/bin/sed"
      WC="${pkgs.coreutils}/bin/wc"

      TRACKERLIST="/tmp/trackers.list"
      trap "rm -f $TRACKERLIST" EXIT

      $WGET https://newtrackon.com/api/stable -O "$TRACKERLIST"
      $WGET https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt -O - >> "$TRACKERLIST"

      $SED -i '/^$/d' "$TRACKERLIST"
      echo "[+] Got $($WC -l < "$TRACKERLIST") trackers"

      while IFS= read -r TRACKER; do
        "$TRANSMISSION_REMOTE" -t all -td "$TRACKER"
      done < "$TRACKERLIST"
    '';
  };

  nixarr = {
    
    enable = true;
    mediaUsers = [ 
      "zeev"  
       ];
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    vpn = {
      enable = true;
      wgConf = "/data/.secret/wg.conf";
      accessibleFrom = [ "127.0.0.1" ]; # Or a more specific subnet
      vpnTestService = {
        port = 58403;
        enable = true;
        };
    };

    transmission = {
      enable = true;
      peerPort = 63998;
      flood.enable = false;
      privateTrackers.cross-seed.enable = true;
      messageLevel = "debug";
      extraSettings = {
        rpc-whitelist-enabled = false;
        rpc-bind-address = "127.0.0.1";
        download-dir = "/data/Downloads";
        # script-torrent-added-enabled = true;
        # script-torrent-added-filename = "/etc/nixos/scripts/add-trackers.sh";
        blocklist-enabled = true;
        blocklist-url = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
      };
    };

    # sabnzbd = {
    #   enable = true;
    #   vpn.enable = true;
    # };

    audiobookshelf.enable = true;
    jellyfin.enable = true;
    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    readarr.enable = true;
    sonarr.enable = true;
    jellyseerr.enable = true;
    readarr-audiobook.enable = true;
  };
}
