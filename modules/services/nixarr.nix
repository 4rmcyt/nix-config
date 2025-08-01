# In ~/src/server/services/nixarr.nix
{ config, pkgs, lib, ... }:
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
      package = pkgs.transmission_4;
      enable = true;
      peerPort = 63998;
      vpn.enable = true;
      flood.enable = false;
      privateTrackers.cross-seed.enable = false;
      extraAllowedIps = [
        "192.168.1.0/24"
        "192.168.0.0/24"
        "127.0.0.1"
      ];
      messageLevel = "info";
      extraSettings = {
        umask = 2;
        download-queue-size = 10;
        download-queue-enabled = true;
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
  };

  systemd.services = lib.genAttrs servicesWithMediaAccess (serviceName: {
    serviceConfig = {
      BindPaths = [
        "/data/Downloads"
        "/data/media"
        "/data/media/movies"
        "/data/media/audiobooks"
        "/data/media/music"
        "/data/media/shows"
        "/data/media/books"
        "/data/media/comics"
        "/data/media/manga"
        "/data/media/torrents"
        "/data/media/usenet"
        "/data/media/audiobooks"
        "/data/Downloads/radarr"
        "/data/Downloads/tv-sonarr"
        "/data/media/.state"
        "/data/media/torrents/.incomplete"
      ];
    };
  });

  systemd.tmpfiles.rules = [
    "d /data 770 root media -"
    "d /data/media/movies 770 zeev media -"
    "d /data/media/audiobooks 770 zeev media -"
    "d /data/media/music 770 zeev media -"
    "d /data/media/shows 770 zeev media -"
    "d /data/media/books 770 zeev media -"
    "d /data/media/comics 770 zeev media -"
    "d /data/media/manga 770 zeev media -"
    "d /data/media/torrents 770 zeev media -"
    "d /data/media/usenet 770 zeev media -"
    "d /data/Downloads 770 zeev users -"


    "d /data/media/.state 770 root media -"
    "d /data/media/.state/nixarr 770 root media -"

    "d /data/media/.state/nixarr/audiobookshelf 775 audiobookshelf audiobookshelf -"
    "d /data/media/.state/nixarr/cross-seed 775 cross-seed cross-seed -"
    "d /data/media/.state/nixarr/jellyfin 755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/data 755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/config 755 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/cache 775 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyfin/log 775 jellyfin jellyfin -"
    "d /data/media/.state/nixarr/jellyseerr 775 jellyseerr jellyseerr -"
    "d /data/media/.state/nixarr/jellyseerr/db 775 jellyseerr jellyseerr -"
    "d /data/media/.state/nixarr/jellyseerr/logs 775 jellyseerr jellyseerr -"
    "d /data/media/.state/nixarr/audiobookshelf/metadata 775 audiobookshelf audiobookshelf -"
    "d /data/media/.state/nixarr/audiobookshelf/config 775 audiobookshelf audiobookshelf -"
    "d /data/media/.state/nixarr/lidarr 775 lidarr lidarr -"
    "d /data/media/.state/nixarr/prowlarr 775 prowlarr prowlarr -"
    "d /data/media/.state/nixarr/radarr 775 radarr radarr -"
    "d /data/media/.state/nixarr/sonarr 775 sonarr sonarr -"
    "d /data/media/.state/nixarr/sabnzbd 775 sabnzbd sabnzbd -"
    "d /data/media/.state/nixarr/bazarr 775 bazarr bazarr -"
    "d /data/media/.state/nixarr/transmission 775 transmission transmission -"

   "d /var/lib/transmission 775 transmission transmission -"

  ];
}
