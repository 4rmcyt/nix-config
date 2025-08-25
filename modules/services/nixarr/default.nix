{
  pkgs,
  lib,
  ...
}:
let
  servicesWithMediaAccess = [
    "bazarr"
    "jellyseerr"
    "lidarr"
    "prowlarr"
    "radarr"
    "sonarr"
    "transmission"
    "audiobookshelf"
    "jellyfin"
  ];
in
{
  users.users = {
    audiobookshelf = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
    };
    bazarr = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
    };
    jellyfin = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
        "render"
      ];
    };
    jellyseerr = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
    };
    lidarr = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
    };
    prowlarr = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
    };
    radarr = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
    };
    sonarr = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
    };
    transmission = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
    };
    recyclarr = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
    };
    flaresolverr = {
      isSystemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
    };
  };
  users.groups = {
    audiobookshelf = { };
    bazarr = { };
    jellyfin = { };
    jellyseerr = { };
    lidarr = { };
    prowlarr = { };
    radarr = { };
    sonarr = { };
    transmission = { };
    recyclarr = { };
    flaresolverr = { };
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
    5055 # Jellyseerr
    9091 # Transmission web UI
    63998 # Transmission peer port
    8191 # FlareSolverr
  ];

  networking.firewall.allowedUDPPorts = [
    63998 # Transmission peer port
    1900 # Jellyfin DLNA
    7359 # Jellyfin discovery
  ];

  # services.nginx = {
  #   enable = true;
  #   recommendedGzipSettings = true;
  #   recommendedOptimisation = true;
  #   recommendedProxySettings = true;
  #   recommendedTlsSettings = true;
  #   virtualHosts = {
  #     "audiobookshelf.labhome.work" = {
  #       forceSSL = true;
  #       sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
  #       sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
  #       locations."/" = {
  #         proxyPass = "http://localhost:9292";
  #         proxyWebsockets = true;
  #       };
  #     };
  #     "jellyfin.labhome.work" = {
  #       forceSSL = true;
  #       sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
  #       sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
  #       locations."/" = {
  #         proxyPass = "http://localhost:8096";
  #         proxyWebsockets = true;
  #       };
  #     };
  #     "bazarr.labhome.work" = {
  #       forceSSL = true;
  #       sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
  #       sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
  #       locations."/" = {
  #         proxyPass = "http://localhost:6767";
  #         proxyWebsockets = true;
  #       };
  #     };
  #     "lidarr.labhome.work" = {
  #       forceSSL = true;
  #       sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
  #       sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
  #       locations."/" = {
  #         proxyPass = "http://localhost:8686";
  #         proxyWebsockets = true;
  #       };
  #     };
  #     "prowlarr.labhome.work" = {
  #       forceSSL = true;
  #       sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
  #       sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
  #       locations."/" = {
  #         proxyPass = "http://localhost:9696";
  #         proxyWebsockets = true;
  #       };
  #     };
  #     "radarr.labhome.work" = {
  #       forceSSL = true;
  #       sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
  #       sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
  #       locations."/" = {
  #         proxyPass = "http://localhost:7878";
  #         proxyWebsockets = true;
  #       };
  #     };
  #     "sonarr.labhome.work" = {
  #       forceSSL = true;
  #       sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
  #       sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
  #       locations."/" = {
  #         proxyPass = "http://localhost:8989";
  #         proxyWebsockets = true;
  #       };
  #     };
  #     "jellyseerr.labhome.work" = {
  #       forceSSL = true;
  #       sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
  #       sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
  #       http2 = true;
  #       locations."/" = {
  #         proxyPass = "http://localhost:5055";
  #         proxyWebsockets = true;
  #       };
  #     };
  # "transmission.labhome.work" = {
  #   forceSSL = true;
  #   sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
  #   sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
  #   locations."/" = {
  #     proxyPass = "http://localhost:9091";
  #     proxyWebsockets = true;
  #   };
  # };
  #   };
  # };

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
    mediaUsers = [ "zeev" ];
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
      # vpnTestService = {
      #   port = 58403;
      #   enable = true;
      # };
    };

    transmission = {
      package = pkgs.transmission_4;
      enable = true;
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

        # script-torrent-added-enabled = true;
        # script-torrent-added-filename = "/etc/nixos/scripts/add-trackers.sh";
        blocklist-enabled = true;
        blocklist-url = "https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz";
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
    recyclarr = {
      enable = true;
      configFile = "./recyclarr.yaml";
    };
  };

  # services.jellyfin = {
  #   enable = true;
  #   openFirewall = true; # DANGEROUS - opens to all interfaces

  #   # Add proper configuration
  #   dataDir = "/var/lib/jellyfin";
  #   configDir = "/var/lib/jellyfin/config";
  #   cacheDir = "/var/cache/jellyfin"; # Separate cache location

  #   # Security improvements
  #   user = "jellyfin";
  #   group = "jellyfin";
  # };

  # # Add systemd security hardening
  # systemd.services.jellyfin.serviceConfig = {
  #   # Resource limits
  #   MemoryMax = "4G";
  #   CPUQuota = "200%"; # Allow 2 cores max

  #   # Security hardening
  #   NoNewPrivileges = true;
  #   PrivateTmp = true;
  #   ProtectHome = true;
  #   ProtectSystem = "strict";
  #   ReadWritePaths = [
  #     "/var/lib/jellyfin"
  #     "/var/cache/jellyfin"
  #     "/data/media"
  #   ];

  #   # Network restrictions
  #   RestrictAddressFamilies = [
  #     "AF_INET"
  #     "AF_INET6"
  #   ];

  #   # File system restrictions
  #   ProtectKernelTunables = true;
  #   ProtectKernelModules = true;
  #   ProtectControlGroups = true;
  # };

  # # Proper firewall configuration instead of openFirewall = true
  # networking.firewall = {
  #   allowedTCPPorts = [ 8096 ]; # Only Jellyfin HTTP port
  #   # Remove blanket firewall opening
  # };

  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
  ];

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
        # "/data/Downloads/radarr"
        # "/data/Downloads/tv-sonarr"
        "/data/media/.state"
        # "/data/media/torrents/.incomplete"
      ];
    };
  });
  services.flaresolverr = {
    enable = true;
    port = 8191; # Default port is usually 8191
  };
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

    "d /data/Downloads 775 zeev media -"
  ];
}
