{
  pkgs,
  lib,
  config,
  ...
}: let
  servicesWithMediaAccess = [
    "bazarr"
    "jellyseerr"
    "lidarr"
    "prowlarr"
    "radarr"
    "readarr"
    "sonarr"
    "transmission"
    "audiobookshelf"
    "jellyfin"
  ];
in {
  # SOPS secrets for nixarr
  sops.secrets = {
    wg_conf = {
      sopsFile = ../../../secrets/wg.conf;
      format = "binary";
      mode = "0600";
    };
    recyclarr_config = {
      sopsFile = ../../../secrets/recyclarr.yaml;
      format = "yaml";
      mode = "0600";
      owner = "recyclarr";
      group = "recyclarr";
    };
  };

  users.users = {
    audiobookshelf = {
      isSystemUser = true;
      group = lib.mkForce "audiobookshelf";
      extraGroups = [
        "users"
        "media"
      ];
    };
    bazarr = {
      isSystemUser = true;
      group = lib.mkForce "bazarr";
      extraGroups = [
        "users"
        "media"
      ];
    };
    jellyfin = {
      isSystemUser = true;
      group = lib.mkForce "jellyfin"; # Add this for consistency
      extraGroups = [
        "users"
        "media"
        "render"
        "video"
      ];
    };
    jellyseerr = {
      isSystemUser = true;
      group = lib.mkForce "jellyseerr"; # Add this for consistency
      extraGroups = [
        "users"
        "media"
      ];
    };
    lidarr = {
      isSystemUser = true;
      group = lib.mkForce "lidarr"; # Add this for consistency
      extraGroups = [
        "users"
        "media"
      ];
    };
    prowlarr = {
      isSystemUser = true;
      group = lib.mkForce "prowlarr"; # Add this for consistency
      extraGroups = [
        "users"
        "media"
      ];
    };
    radarr = {
      isSystemUser = true;
      group = lib.mkForce "radarr"; # Add this for consistency
      extraGroups = [
        "users"
        "media"
      ];
    };
    sonarr = {
      isSystemUser = true;
      group = lib.mkForce "sonarr";
      extraGroups = [
        "users"
        "media"
      ];
    };
    readarr = {
      isSystemUser = true;
      group = lib.mkForce "readarr";
      extraGroups = [
        "users"
        "media"
      ];
    };
    transmission = {
      isSystemUser = true;
      group = lib.mkForce "transmission";
      extraGroups = [
        "users"
        "media"
      ];
    };
    recyclarr = {
      isSystemUser = true;
      group = lib.mkForce "recyclarr";
      extraGroups = [
        "users"
        "media"
      ];
    };
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
    readarr = {};
    recyclarr = {};
    # headphones = { };
  };

  networking.firewall.allowedTCPPorts = [
    9292 # Audiobookshelf
    8096 # Jellyfin
    8920 # Jellyfin HTTPS
    6767 # Bazarr
    8686 # Lidarr
    9696 # Prowlarr
    7878 # Radarr
    8989 # Sonarr
    8787 # Readarr
    5055 # Jellyseerr
    9091 # Transmission web UI
    63998 # Transmission peer port
  ];

  networking.firewall.allowedUDPPorts = [
    63998 # Transmission peer port
    1900 # Jellyfin DLNA
    7359 # Jellyfin discovery
  ];

  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
  ];

  nixarr = {
    enable = true;
    mediaUsers = [config.my.defaults.user];
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    vpn = {
      enable = true;
      wgConf = config.sops.secrets.wg_conf.path;
      openTcpPorts = [
        58403
        63998
        9091
      ];
    };

    transmission = {
      enable = true;
      # package = pkgs.transmission_4;
      peerPort = 63998;
      vpn.enable = true;
      flood.enable = false;
      openFirewall = true;
      uiPort = 9091;
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
        rpc-bind-address = "0.0.0.0";
        rpc-enabled = true;
        rpc-port = 9091;
        download-dir = "/data/Downloads";

        peer-port = 63998;
        peer-port-random-on-start = false;
        port-forwarding-enabled = true;
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
    readarr.enable = true;
    recyclarr = {
      enable = true;
      configFile = config.sops.secrets.recyclarr_config.path;
    };
  };

  systemd.services = lib.genAttrs servicesWithMediaAccess (_serviceName: {
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
        "/data/Downloads/lidarr"
        "/data/Downloads/tv-sonarr"
        "/data/media/.state"
        # "/data/media/torrents/.incomplete"
      ];
    };
  });
  systemd.tmpfiles.rules = [
    "d /data 770 root media -"
    "d /data/media/movies 775 zeev media -" # Changed from 770 to 775
    "d /data/media/audiobooks 775 zeev media -"
    "d /data/media/music 775 zeev media -"
    "d /data/media/shows 775 zeev media -" # Changed from 770 to 775
    "d /data/media/books 775 zeev media -"
    "d /data/media/comics 775 zeev media -"
    "d /data/media/manga 775 zeev media -"
    "d /data/media/torrents 775 zeev media -"
    "d /data/media/usenet 775 zeev media -"
    "d /data/Downloads 775 zeev users -" # Changed from 770 to 775

    "d /data/media/.state 770 root media -"
    "d /data/media/.state/nixarr 770 root media -"

    "d /data/media/.state/nixarr/audiobookshelf 775 audiobookshelf audiobookshelf -"
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
    "d /data/media/.state/headphones 775 headphones headphones -"
    "d /data/media/.state/nixarr/transmission 775 transmission transmission -"

    # Add rules to fix ownership of existing directories
    "Z /data/media/movies 775 zeev media -"
    "Z /data/media/shows 775 zeev media -"
    "Z /data/media/music 775 zeev media -"
    "Z /data/media/audiobooks 775 zeev media -"
    "Z /data/media/books 775 zeev media -"
    "Z /data/media/comics 775 zeev media -"
    "Z /data/media/manga 775 zeev media -"

    "d /var/lib/transmission 775 transmission transmission -"

    "d /data/Downloads 775 zeev media -"
  ];
}
