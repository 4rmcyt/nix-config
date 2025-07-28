# In ~/src/server/services/nixarr.nix
{ config, pkgs, ... }:
let
  servicesWithMediaAccess = [
    "bazarr"
    "cross-seed"
    "jellyseerr"
    "lidarr"
    "prowlarr"
    "radarr"
    "sonarr"
    "transmission"
    "audiobookshelf"
    "jellyfin"
    "kavita"
    "calibre-web"
  ];
in  
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
      # accessibleFrom = [
      #   "192.168.1.0/24"
      #   "192.168.0.0/24"
      #   "127.0.0.1"
      # ];
      openTcpPorts = [
        58403
        63998
        9091
      ];
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
      extraAllowedIps = [
        "192.168.1.0/24"
        "192.168.0.0/24"
        "127.0.0.1"
      ];
      messageLevel = "debug";
      extraSettings = {
        umask = 2;
        rpc-whitelist-enabled = false;
        download-dir = "/data/Downloads";
        # script-torrent-added-enabled = true;
        # script-torrent-added-filename = "/etc/nixos/scripts/add-trackers.sh";
        blocklist-enabled = true;
        blocklist-url = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
      };
    };

    audiobookshelf.enable = true;
    jellyfin.enable = true;
    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    sonarr.enable = true;
    jellyseerr.enable = true;
  };

  users.users = {
    audiobookshelf = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
    bazarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
    jellyfin = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
    jellyseerr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
    lidarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
    prowlarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
    radarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
    sonarr = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
    transmission = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
    cross-seed = { isSystemUser = true; extraGroups = [ "users" "media" ]; };
  };
  users.groups = {
    audiobookshelf = {};
    bazarr = {};
    jellyfin = {};
    jellyseerr = {};
    lidarr = {};
    prowlarr = {};
    radarr = {};
    sonarr = {};
    transmission = {};
    cross-seed = {};
  };

  systemd.services = lib.genAttrs servicesWithMediaAccess (serviceName: {
    serviceConfig = {
      BindPaths = [
        "/data/Downloads"
        "/data/media"
      ];
    };
  });

  systemd.tmpfiles.rules = [
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

    
 
    "d /data/media 0775 root media -"
    "d /data/media/library 0775 zeev media -"
    "d /data/media/torrents 0775 zeev media -"
    "d /data/media/usenet 0775 zeev media -"

    "d /data/media/.state 0775 root media -"
    "d /data/media/.state/nixarr 0775 root media -"

    "d /data/media/.state/nixarr/audiobookshelf 0775 audiobookshelf audiobookshelf -"
    "d /data/media/.state/nixarr/cross-seed 0775 cross-seed cross-seed -"
    "d /data/media/.state/nixarr/jellyfin 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/data 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/config 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/cache 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/log 0755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/audiobookshelf/metadata 0755 jellyfin jellyfin -"

    "d /data/media/.state/nixarr/lidarr 0775 lidarr lidarr -"
    "d /data/media/.state/nixarr/prowlarr 0775 prowlarr prowlarr -"
    "d /data/media/.state/nixarr/radarr 0775 radarr radarr -"
    "d /data/media/.state/nixarr/sonarr 0775 sonarr sonarr -"
    "d /data/media/.state/nixarr/sabnzbd 0775 sabnzbd sabnzbd -"
    "d /data/media/.state/nixarr/bazarr 0775 bazarr bazarr -"
    "d /data/media/.state/nixarr/transmission 0775 transmission transmission -"

    "d /data/media/.state/nixarr/jellyseerr 0775 jellyseerr jellyseerr -"
    "d /data/media/.state/nixarr/jellyseerr/db 0775 jellyseerr jellyseerr -" 
    "d /data/media/.state/nixarr/jellyseerr/logs 0755 jellyseerr jellyseerr -"

    "d /var/lib/transmission 0775 transmission transmission -"

  ];
}
