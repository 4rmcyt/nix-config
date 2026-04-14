{
  lib,
  config,
  pkgs,
  ...
}: let
  servicesWithMediaAccess = [
    "audiobookshelf"
    "bazarr"
    "jackett"
    "jellyfin"
    "jellyseerr"
    "lidarr"
    "prowlarr"
    "qbittorrent"
    "radarr"
    "readarr"
    "sonarr"
  ];

  servicesWithScripts = [
    "bazarr"
    "lidarr"
    "radarr"
    "sonarr"
  ];

  movieCleaner = pkgs.writeShellApplication {
    name = "movie-cleaner";
    runtimeInputs = with pkgs; [
      mkvtoolnix-cli
      jq
      curl
      coreutils
    ];
    text = builtins.readFile ./scripts/movie-cleaner.sh;
  };

  showCleaner = pkgs.writeShellApplication {
    name = "show-cleaner";
    runtimeInputs = with pkgs; [
      mkvtoolnix-cli
      jq
      curl
      coreutils
    ];
    text = builtins.readFile ./scripts/show-cleaner.sh;
  };

  musicConverter = pkgs.writeShellApplication {
    name = "music-converter";
    runtimeInputs = with pkgs; [
      ffmpeg-headless
      flac
      shntool
      cuetools
      curl
      coreutils
      util-linux
    ];
    text = builtins.readFile ./scripts/music-converter.sh;
  };

  bazarrBridge = pkgs.writeShellApplication {
    name = "bazarr-bridge";
    runtimeInputs = [
      movieCleaner
      showCleaner
    ];
    text = builtins.readFile ./scripts/bazarr-bridge.sh;
  };
in {
  imports = [
    ./jackett
    ./jellyfin
    ./kapowarr
    ./qbittorrent
    ./upnp-fix.nix
  ];

  sops.secrets = {
    bazarr_api_key = {
      sopsFile = ../../../secrets/medialib.yaml;
      owner = config.my.defaults.user;
      key = "bazarr_api_key";
      group = "media";
      mode = "0440";
    };
    jellyfin_api_key = {
      sopsFile = ../../../secrets/medialib.yaml;
      owner = config.my.defaults.user;
      key = "jellyfin_api_key";
      group = "media";
      mode = "0440";
    };
    lidarr_api_key = {
      sopsFile = ../../../secrets/medialib.yaml;
      owner = config.my.defaults.user;
      key = "lidarr_api_key";
      group = "media";
      mode = "0440";
    };
  };

  users.users =
    lib.genAttrs
    [
      "audiobookshelf"
      "bazarr"
      "jackett"
      "jellyseerr"
      "lidarr"
      "prowlarr"
      "radarr"
      "sonarr"
      "readarr"
      "recyclarr"
    ]
    (name: {
      isSystemUser = true;
      group = lib.mkForce name;
      extraGroups = [
        "users"
        "media"
      ];
    });

  users.groups = lib.genAttrs [
    "audiobookshelf"
    "bazarr"
    "jackett"
    "jellyseerr"
    "lidarr"
    "prowlarr"
    "radarr"
    "sonarr"
    "readarr"
    "recyclarr"
  ] (_: {});

  environment.systemPackages = with pkgs; [
    movieCleaner
    showCleaner
    musicConverter
    bazarrBridge
    mkvtoolnix-cli
    shntool
    cuetools
  ];

  services.flaresolverr = {
    enable = true;
    port = 8191;
    openFirewall = true;
  };

  nixarr = {
    enable = true;
    mediaUsers = [config.my.defaults.user];
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    audiobookshelf.enable = true;
    jellyseerr.enable = true;
    jellyfin.enable = false; # Handled by ./jellyfin
    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    sonarr = {
      enable = true;
      port = 8990;
    };
    readarr.enable = true;
    recyclarr = {
      enable = true;
      configFile = ./recyclarr.yaml;
    };
  };

  systemd.services = lib.mkMerge [
    (lib.genAttrs servicesWithMediaAccess (_name: {
      serviceConfig = {
        UMask = lib.mkForce "0002";
        BindPaths = [
          "/data/Downloads"
          "/data/media"
          "/data/media/.state"
        ];
      };
    }))
    (lib.genAttrs servicesWithScripts (_name: {
      path = [
        movieCleaner
        showCleaner
        musicConverter
        bazarrBridge
      ];
      serviceConfig.Environment = [
        "JF_URL=http://localhost:8096"
        "JF_API_KEY_FILE=${config.sops.secrets.jellyfin_api_key.path}"
        "LIDARR_URL=http://localhost:8686"
        "LIDARR_API_KEY_FILE=${config.sops.secrets.lidarr_api_key.path}"
        "BAZARR_URL=http://localhost:6767"
        "BAZARR_API_KEY_FILE=${config.sops.secrets.bazarr_api_key.path}"
      ];
    }))
    {
      radarr-pg-config = {
        description = "Write Radarr PostgreSQL config.xml";
        after = [
          "postgresql.service"
          "postgresql-setup-users.service"
        ];
        requires = ["postgresql.service"];
        wantedBy = ["multi-user.target"];
        before = ["radarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "radarr";
          Group = "radarr";
        };
        path = [pkgs.xmlstarlet];
        script = ''
          mkdir -p /data/media/.state/nixarr/radarr
          cfg=/data/media/.state/nixarr/radarr/config.xml
          if [ ! -f "$cfg" ]; then
            printf '<Config>\n</Config>\n' > "$cfg"
          fi
          PG_PASS=$(cat ${config.sops.secrets.radarr_db_password.path} | tr -d '\n\r')
          for pair in "PostgresUser:radarr" "PostgresPassword:$PG_PASS" "PostgresPort:5432" "PostgresHost:127.0.0.1" "PostgresMainDb:radarr" "PostgresLogDb:radarr-log"; do
            key="''${pair%%:*}"
            val="''${pair#*:}"
            if xmlstarlet sel -t -v "count(/Config/$key)" "$cfg" 2>/dev/null | grep -q "^0$"; then
              xmlstarlet ed -L -s /Config -t elem -n "$key" -v "$val" "$cfg"
            else
              xmlstarlet ed -L -u "/Config/$key" -v "$val" "$cfg"
            fi
          done
          chmod 600 "$cfg"
        '';
      };
      sonarr-pg-config = {
        description = "Write Sonarr PostgreSQL config.xml";
        after = [
          "postgresql.service"
          "postgresql-setup-users.service"
        ];
        requires = ["postgresql.service"];
        wantedBy = ["multi-user.target"];
        before = ["sonarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "sonarr";
          Group = "sonarr";
        };
        path = [pkgs.xmlstarlet];
        script = ''
          mkdir -p /data/media/.state/nixarr/sonarr
          cfg=/data/media/.state/nixarr/sonarr/config.xml
          if [ ! -f "$cfg" ]; then
            printf '<Config>\n</Config>\n' > "$cfg"
          fi
          PG_PASS=$(cat ${config.sops.secrets.sonarr_db_password.path} | tr -d '\n\r')
          for pair in "PostgresUser:sonarr" "PostgresPassword:$PG_PASS" "PostgresPort:5432" "PostgresHost:127.0.0.1" "PostgresMainDb:sonarr" "PostgresLogDb:sonarr-log"; do
            key="''${pair%%:*}"
            val="''${pair#*:}"
            if xmlstarlet sel -t -v "count(/Config/$key)" "$cfg" 2>/dev/null | grep -q "^0$"; then
              xmlstarlet ed -L -s /Config -t elem -n "$key" -v "$val" "$cfg"
            else
              xmlstarlet ed -L -u "/Config/$key" -v "$val" "$cfg"
            fi
          done
          chmod 600 "$cfg"
        '';
      };
      prowlarr-pg-config = {
        description = "Write Prowlarr PostgreSQL config.xml";
        after = [
          "postgresql.service"
          "postgresql-setup-users.service"
        ];
        requires = ["postgresql.service"];
        wantedBy = ["multi-user.target"];
        before = ["prowlarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "prowlarr";
          Group = "prowlarr";
        };
        path = [pkgs.xmlstarlet];
        script = ''
          mkdir -p /data/media/.state/nixarr/prowlarr
          cfg=/data/media/.state/nixarr/prowlarr/config.xml
          if [ ! -f "$cfg" ]; then
            printf '<Config>\n</Config>\n' > "$cfg"
          fi
          PG_PASS=$(cat ${config.sops.secrets.prowlarr_db_password.path} | tr -d '\n\r')
          for pair in "PostgresUser:prowlarr" "PostgresPassword:$PG_PASS" "PostgresPort:5432" "PostgresHost:127.0.0.1" "PostgresMainDb:prowlarr" "PostgresLogDb:prowlarr-log"; do
            key="''${pair%%:*}"
            val="''${pair#*:}"
            if xmlstarlet sel -t -v "count(/Config/$key)" "$cfg" 2>/dev/null | grep -q "^0$"; then
              xmlstarlet ed -L -s /Config -t elem -n "$key" -v "$val" "$cfg"
            else
              xmlstarlet ed -L -u "/Config/$key" -v "$val" "$cfg"
            fi
          done
          chmod 600 "$cfg"
        '';
      };
      lidarr-pg-config = {
        description = "Write Lidarr PostgreSQL config.xml";
        after = [
          "postgresql.service"
          "postgresql-setup-users.service"
        ];
        requires = ["postgresql.service"];
        wantedBy = ["multi-user.target"];
        before = ["lidarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "lidarr";
          Group = "lidarr";
        };
        path = [pkgs.xmlstarlet];
        script = ''
          mkdir -p /data/media/.state/nixarr/lidarr
          cfg=/data/media/.state/nixarr/lidarr/config.xml
          if [ ! -f "$cfg" ]; then
            printf '<Config>\n</Config>\n' > "$cfg"
          fi
          PG_PASS=$(cat ${config.sops.secrets.lidarr_db_password.path} | tr -d '\n\r')
          for pair in "PostgresUser:lidarr" "PostgresPassword:$PG_PASS" "PostgresPort:5432" "PostgresHost:127.0.0.1" "PostgresMainDb:lidarr" "PostgresLogDb:lidarr-log"; do
            key="''${pair%%:*}"
            val="''${pair#*:}"
            if xmlstarlet sel -t -v "count(/Config/$key)" "$cfg" 2>/dev/null | grep -q "^0$"; then
              xmlstarlet ed -L -s /Config -t elem -n "$key" -v "$val" "$cfg"
            else
              xmlstarlet ed -L -u "/Config/$key" -v "$val" "$cfg"
            fi
          done
          chmod 600 "$cfg"
        '';
      };
      readarr-pg-config = {
        description = "Write Readarr PostgreSQL config.xml";
        after = [
          "postgresql.service"
          "postgresql-setup-users.service"
        ];
        requires = ["postgresql.service"];
        wantedBy = ["multi-user.target"];
        before = ["readarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "readarr";
          Group = "readarr";
        };
        path = [pkgs.xmlstarlet];
        script = ''
          mkdir -p /data/media/.state/nixarr/readarr
          cfg=/data/media/.state/nixarr/readarr/config.xml
          if [ ! -f "$cfg" ]; then
            printf '<Config>\n</Config>\n' > "$cfg"
          fi
          PG_PASS=$(cat ${config.sops.secrets.readarr_db_password.path} | tr -d '\n\r')
          for pair in "PostgresUser:readarr" "PostgresPassword:$PG_PASS" "PostgresPort:5432" "PostgresHost:127.0.0.1" "PostgresMainDb:readarr" "PostgresLogDb:readarr-log" "PostgresCacheDb:readarr-cache"; do
            key="''${pair%%:*}"
            val="''${pair#*:}"
            if xmlstarlet sel -t -v "count(/Config/$key)" "$cfg" 2>/dev/null | grep -q "^0$"; then
              xmlstarlet ed -L -s /Config -t elem -n "$key" -v "$val" "$cfg"
            else
              xmlstarlet ed -L -u "/Config/$key" -v "$val" "$cfg"
            fi
          done
          chmod 600 "$cfg"
        '';
      };
      bazarr-pg-env = {
        description = "Write Bazarr PostgreSQL environment file";
        after = [
          "postgresql.service"
          "postgresql-setup-users.service"
        ];
        requires = ["postgresql.service"];
        wantedBy = ["bazarr.service"];
        before = ["bazarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          RuntimeDirectory = "bazarr-secrets";
          RuntimeDirectoryMode = "0750";
          User = "bazarr";
          Group = "bazarr";
        };
        script = ''
          printf 'POSTGRES_ENABLED=true\nPOSTGRES_HOST=127.0.0.1\nPOSTGRES_PORT=5432\nPOSTGRES_DATABASE=bazarr\nPOSTGRES_USERNAME=bazarr\nPOSTGRES_PASSWORD=%s\n' \
            "$(cat ${config.sops.secrets.bazarr_db_password.path} | tr -d '\n\r')" \
            > /run/bazarr-secrets/pg-env
          chmod 600 /run/bazarr-secrets/pg-env
        '';
      };
      bazarr.serviceConfig.EnvironmentFile = "/run/bazarr-secrets/pg-env";
    }
  ];

  systemd.tmpfiles.rules = [
    "d /data 770 root media -"
    "d /data/media 775 ${config.my.defaults.user} media -"
    "d /data/Downloads 775 ${config.my.defaults.user} media -"

    "d /data/media/movies 2775 ${config.my.defaults.user} media -"
    "d /data/media/shows 2775 ${config.my.defaults.user} media -"
    "d /data/media/music 775 ${config.my.defaults.user} media -"
    "d /data/media/audiobooks 775 ${config.my.defaults.user} media -"
    "d /data/media/books 775 ${config.my.defaults.user} media -"
    "d /data/media/comics 775 ${config.my.defaults.user} media -"
    "d /data/media/manga 775 ${config.my.defaults.user} media -"

    "d /data/Downloads/tv-sonarr 775 ${config.my.defaults.user} media -"
    "d /data/Downloads/radarr 775 ${config.my.defaults.user} media -"
    "d /data/Downloads/lidarr 775 ${config.my.defaults.user} media -"
    "d /data/Downloads/audiobooks 775 ${config.my.defaults.user} media -"

    "d /data/media/.state 770 root media -"
    "d /data/media/.state/nixarr 770 root media -"
    "d /data/media/.state/nixarr/jellyseerr 775 jellyseerr jellyseerr -"
    "d /data/media/.state/nixarr/audiobookshelf 775 audiobookshelf audiobookshelf -"
    "d /data/media/.state/nixarr/audiobookshelf/metadata 775 audiobookshelf audiobookshelf -"
    "d /data/media/.state/nixarr/audiobookshelf/config 775 audiobookshelf audiobookshelf -"
    "d /data/media/.state/nixarr/lidarr 775 lidarr lidarr -"
    "d /data/media/.state/nixarr/prowlarr 775 prowlarr prowlarr -"
    "d /data/media/.state/nixarr/radarr 775 radarr radarr -"
    "d /data/media/.state/nixarr/sonarr 775 sonarr sonarr -"
    "d /data/media/.state/nixarr/bazarr 775 bazarr bazarr -"

    "Z /data/media/movies 2775 ${config.my.defaults.user} media -"
    "Z /data/media/shows 2775 ${config.my.defaults.user} media -"
    "Z /data/media/music 775 ${config.my.defaults.user} media -"
    "Z /data/media/audiobooks 775 ${config.my.defaults.user} media -"
    "Z /data/media/books 775 ${config.my.defaults.user} media -"
    "Z /data/media/comics 775 ${config.my.defaults.user} media -"
    "Z /data/media/manga 775 ${config.my.defaults.user} media -"
    "Z /data/Downloads 775 ${config.my.defaults.user} media -"
  ];

  networking.firewall.allowedTCPPorts = [
    5055 # Jellyseerr
    6767 # Bazarr
    7878 # Radarr
    8096 # Jellyfin HTTP
    8686 # Lidarr
    8787 # Readarr
    8920 # Jellyfin HTTPS
    8990 # Sonarr
    9117 # Jackett
    9292 # Audiobookshelf
    9696 # Prowlarr
  ];
  networking.firewall.allowedUDPPorts = [
    1900 # DLNA/UPnP
    7359 # Jellyfin auto-discovery
  ];
}
