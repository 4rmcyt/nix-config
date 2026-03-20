{
  lib,
  config,
  pkgs,
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
    "qbittorrent"
    "audiobookshelf"
    "jellyfin"
  ];

  servicesWithScripts = ["bazarr" "lidarr" "radarr" "sonarr"];

  movieCleaner = pkgs.writeShellApplication {
    name = "movie-cleaner";
    runtimeInputs = with pkgs; [mkvtoolnix-cli jq curl coreutils];
    text = builtins.readFile ./scripts/movie-cleaner.sh;
  };

  showCleaner = pkgs.writeShellApplication {
    name = "show-cleaner";
    runtimeInputs = with pkgs; [mkvtoolnix-cli jq curl coreutils];
    text = builtins.readFile ./scripts/show-cleaner.sh;
  };

  musicConverter = pkgs.writeShellApplication {
    name = "music-converter";
    runtimeInputs = with pkgs; [ffmpeg-headless flac shntool cuetools curl coreutils util-linux];
    text = builtins.readFile ./scripts/music-converter.sh;
  };

  bazarrBridge = pkgs.writeShellApplication {
    name = "bazarr-bridge";
    runtimeInputs = [movieCleaner showCleaner];
    text = builtins.readFile ./scripts/bazarr-bridge.sh;
  };
in {
  imports = [
    ./upnp-fix.nix
    ./jellyfin
    ./qbittorrent
    # ./slskd
  ];

  sops.secrets = {
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
    bazarr_api_key = {
      sopsFile = ../../../secrets/medialib.yaml;
      owner = config.my.defaults.user;
      key = "bazarr_api_key";
      group = "media";
      mode = "0440";
    };
  };

  users.users =
    lib.genAttrs [
      "audiobookshelf"
      "bazarr"
      "jellyseerr"
      "lidarr"
      "prowlarr"
      "radarr"
      "sonarr"
      "readarr"
      "recyclarr"
    ] (name: {
      isSystemUser = true;
      group = lib.mkForce name;
      extraGroups = ["users" "media"];
    });

  users.groups = lib.genAttrs [
    "audiobookshelf"
    "bazarr"
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
        UMask = lib.mkDefault "0002";
        BindPaths = [
          "/data/Downloads"
          "/data/media"
          "/data/media/.state"
        ];
      };
    }))
    (lib.genAttrs servicesWithScripts (_name: {
      path = [movieCleaner showCleaner musicConverter bazarrBridge];
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
        after = ["postgresql.service" "postgresql-setup-users.service"];
        requires = ["postgresql.service"];
        wantedBy = ["radarr.service"];
        before = ["radarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "radarr";
          Group = "radarr";
        };
        script = ''
          mkdir -p /data/media/.state/nixarr/radarr
          cat > /data/media/.state/nixarr/radarr/config.xml <<EOF
          <Config>
            <PostgresUser>radarr</PostgresUser>
            <PostgresPassword>$(cat ${config.sops.secrets.radarr_db_password.path} | tr -d '\n\r')</PostgresPassword>
            <PostgresPort>5432</PostgresPort>
            <PostgresHost>127.0.0.1</PostgresHost>
            <PostgresMainDb>radarr</PostgresMainDb>
            <PostgresLogDb>radarr-log</PostgresLogDb>
          </Config>
          EOF
          chmod 600 /data/media/.state/nixarr/radarr/config.xml
        '';
      };
      sonarr-pg-config = {
        description = "Write Sonarr PostgreSQL config.xml";
        after = ["postgresql.service" "postgresql-setup-users.service"];
        requires = ["postgresql.service"];
        wantedBy = ["sonarr.service"];
        before = ["sonarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "sonarr";
          Group = "sonarr";
        };
        script = ''
          mkdir -p /data/media/.state/nixarr/sonarr
          cat > /data/media/.state/nixarr/sonarr/config.xml <<EOF
          <Config>
            <PostgresUser>sonarr</PostgresUser>
            <PostgresPassword>$(cat ${config.sops.secrets.sonarr_db_password.path} | tr -d '\n\r')</PostgresPassword>
            <PostgresPort>5432</PostgresPort>
            <PostgresHost>127.0.0.1</PostgresHost>
            <PostgresMainDb>sonarr</PostgresMainDb>
            <PostgresLogDb>sonarr-log</PostgresLogDb>
          </Config>
          EOF
          chmod 600 /data/media/.state/nixarr/sonarr/config.xml
        '';
      };
      prowlarr-pg-config = {
        description = "Write Prowlarr PostgreSQL config.xml";
        after = ["postgresql.service" "postgresql-setup-users.service"];
        requires = ["postgresql.service"];
        wantedBy = ["prowlarr.service"];
        before = ["prowlarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "prowlarr";
          Group = "prowlarr";
        };
        script = ''
          mkdir -p /data/media/.state/nixarr/prowlarr
          cat > /data/media/.state/nixarr/prowlarr/config.xml <<EOF
          <Config>
            <PostgresUser>prowlarr</PostgresUser>
            <PostgresPassword>$(cat ${config.sops.secrets.prowlarr_db_password.path} | tr -d '\n\r')</PostgresPassword>
            <PostgresPort>5432</PostgresPort>
            <PostgresHost>127.0.0.1</PostgresHost>
            <PostgresMainDb>prowlarr</PostgresMainDb>
            <PostgresLogDb>prowlarr-log</PostgresLogDb>
          </Config>
          EOF
          chmod 600 /data/media/.state/nixarr/prowlarr/config.xml
        '';
      };
      lidarr-pg-config = {
        description = "Write Lidarr PostgreSQL config.xml";
        after = ["postgresql.service" "postgresql-setup-users.service"];
        requires = ["postgresql.service"];
        wantedBy = ["lidarr.service"];
        before = ["lidarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "lidarr";
          Group = "lidarr";
        };
        script = ''
          mkdir -p /data/media/.state/nixarr/lidarr
          cat > /data/media/.state/nixarr/lidarr/config.xml <<EOF
          <Config>
            <PostgresUser>lidarr</PostgresUser>
            <PostgresPassword>$(cat ${config.sops.secrets.lidarr_db_password.path} | tr -d '\n\r')</PostgresPassword>
            <PostgresPort>5432</PostgresPort>
            <PostgresHost>127.0.0.1</PostgresHost>
            <PostgresMainDb>lidarr</PostgresMainDb>
            <PostgresLogDb>lidarr-log</PostgresLogDb>
          </Config>
          EOF
          chmod 600 /data/media/.state/nixarr/lidarr/config.xml
        '';
      };
      readarr-pg-config = {
        description = "Write Readarr PostgreSQL config.xml";
        after = ["postgresql.service" "postgresql-setup-users.service"];
        requires = ["postgresql.service"];
        wantedBy = ["readarr.service"];
        before = ["readarr.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "readarr";
          Group = "readarr";
        };
        script = ''
          mkdir -p /data/media/.state/nixarr/readarr
          cat > /data/media/.state/nixarr/readarr/config.xml <<EOF
          <Config>
            <PostgresUser>readarr</PostgresUser>
            <PostgresPassword>$(cat ${config.sops.secrets.readarr_db_password.path} | tr -d '\n\r')</PostgresPassword>
            <PostgresPort>5432</PostgresPort>
            <PostgresHost>127.0.0.1</PostgresHost>
            <PostgresMainDb>readarr</PostgresMainDb>
            <PostgresLogDb>readarr-log</PostgresLogDb>
          </Config>
          EOF
          chmod 600 /data/media/.state/nixarr/readarr/config.xml
        '';
      };
      bazarr-pg-env = {
        description = "Write Bazarr PostgreSQL environment file";
        after = ["postgresql.service" "postgresql-setup-users.service"];
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

  networking.firewall.allowedTCPPorts = [9292 8096 8920 6767 8686 9696 7878 8990 8787 5055];
  networking.firewall.allowedUDPPorts = [1900 7359];
}
