{
  lib,
  config,
  ...
}:
let
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
in
{
  imports = [
    ./upnp-fix.nix
  ];
  
  # SOPS secrets for nixarr
  sops.secrets = {
    wg_conf = {
      sopsFile = ../../../secrets/wg.conf;
      format = "binary";
      mode = "0600";
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
      group = lib.mkForce "jellyfin";
      extraGroups = [
        "users"
        "media"
        "render"
        "video"
        "input"
      ];
    };
    jellyseerr = {
      isSystemUser = true;
      group = lib.mkForce "jellyseerr";
      extraGroups = [
        "users"
        "media"
      ];
    };
    lidarr = {
      isSystemUser = true;
      group = lib.mkForce "lidarr";
      extraGroups = [
        "users"
        "media"
      ];
    };
    prowlarr = {
      isSystemUser = true;
      group = lib.mkForce "prowlarr";
      extraGroups = [
        "users"
        "media"
      ];
    };
    radarr = {
      isSystemUser = true;
      group = lib.mkForce "radarr";
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
    audiobookshelf = { };
    bazarr = { };
    jellyfin = { };
    jellyseerr = { };
    lidarr = { };
    prowlarr = { };
    radarr = { };
    sonarr = { };
    transmission = { };
    readarr = { };
    recyclarr = { };
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

  util-nixarr.upnp = {
    enable = true;
    openTcpPorts = [
      # 80    # HTTP - conflicts with existing router mapping
      # 443   # HTTPS - conflicts with existing router mapping
      8096 # Jellyfin
      8920 # Jellyfin HTTPS
      9292 # Audiobookshelf
      5055 # Jellyseerr
    ];
    openUdpPorts = [
      1900 # Jellyfin DLNA
      7359 # Jellyfin discovery
    ];
  };

  # Jellyfin declarative configuration using nixos-jellyfin module
  services.jellyfin = {
    enable = true;

    settings = {
      # Base configuration
      isStartupWizardCompleted = true;
      cachePath = "/data/media/.state/nixarr/jellyfin/cache";
      logFileRetentionDays = 3;

      # Server identity
      serverName = "homeserver";
      displayLanguage = "en-US";

      # Hardware acceleration (VAAPI for Intel/AMD)
      hardwareAccelerationType = "vaapi";
      vaapiDevice = "/dev/dri/renderD128";
      enableHardwareEncoding = true;
      preferSystemNativeHwDecoder = true;
      hardwareDecodingCodecs = [ "h264" "hevc" "mpeg2video" "vp8" "vp9" "vc1" ];

      # Tone mapping for HDR content
      enableTonemapping = true;
      enableVppTonemapping = false;
      tonemappingAlgorithm = "bt2390";
      tonemappingMode = "auto";
      tonemappingRange = "auto";
      tonemappingDesat = 0;
      tonemappingPeak = 100;
      tonemappingParam = 0;
      vppTonemappingBrightness = 16;
      vppTonemappingContrast = 1;

      # Encoding quality settings
      encodingThreadCount = 4;
      h264Crf = 23;
      h265Crf = 28;
      encoderPreset = "superfast";
      allowHevcEncoding = true;
      allowAv1Encoding = false;

      # Enable 10-bit codec support
      enableDecodingColorDepth10Hevc = true;
      enableDecodingColorDepth10Vp9 = true;

      # Intel low-power encoders
      enableIntelLowPowerH264HwEncoder = true;
      enableIntelLowPowerHevcHwEncoder = false;

      # Enhanced decoder
      enableEnhancedNvdecDecoder = true;

      # Audio settings
      enableAudioVbr = false;
      downMixAudioBoost = 2;
      downMixStereoAlgorithm = "none";

      # Deinterlacing
      deinterlaceDoubleRate = false;
      deinterlaceMethod = "yadif";

      # Transcoding settings
      transcodingTempPath = "/data/media/.state/nixarr/jellyfin/cache/transcodes";
      maxMuxingQueueSize = 2048;
      enableThrottling = true;
      throttleDelaySeconds = 180;
      enableSegmentDeletion = true;
      segmentKeepSeconds = 720;

      # Subtitle extraction
      enableSubtitleExtraction = true;
      enableFallbackFont = false;

      # Keyframe extraction
      allowOnDemandMetadataBasedKeyframeExtractionForExtensions = [ "mkv" ];

      # Metadata configuration
      metadataPath = "/data/media/.state/nixarr/jellyfin/data/metadata";
      preferredMetadataLanguage = "en";
      metadataCountryCode = "CA";

      # Library monitoring
      libraryMonitorDelay = 60;
      libraryUpdateDuration = 30;
      libraryScanFanoutConcurrency = 2;
      libraryMetadataRefreshConcurrency = 0;

      # Playback state tracking
      minResumePct = 5;
      maxResumePct = 90;
      minResumeDurationSeconds = 300;
      minAudiobookResume = 5;
      maxAudiobookResume = 5;
      inactiveSessionThreshold = 0;

      # Images
      imageSavingConvention = "Legacy";
      chapterImageResolution = "matchsource";
      imageExtractionTimeoutMs = 0;
      parallelImageEncodingLimit = 2;
      dummyChapterDuration = 0;

      # Network & Security
      isPortAuthorized = true;
      quickConnectAvailable = true;
      corsHosts = [ "*" ];
      remoteClientBitrateLimit = 120000000;

      # Monitoring & Logging
      enableMetrics = false;
      activityLogRetentionDays = 30;
      enableSlowResponseWarning = true;
      slowResponseThresholdMs = 500;
      allowClientLogUpload = true;

      # Feature flags
      enableNormalizedItemByNameIds = true;
      enableCaseSensitiveItemIds = true;
      disableLiveTvChannelUserDataName = true;
      skipDeserializationForBasicTypes = true;
      saveMetadataHidden = false;
      enableFolderView = false;
      enableGroupingIntoCollections = false;
      displaySpecialsWithinSeasons = true;
      enableExternalContentInSuggestions = true;

      # Plugin repositories
      pluginRepositories = [
        {
          name = "Jellyfin Stable";
          url = "https://repo.jellyfin.org/files/plugin/manifest.json";
          enabled = true;
        }
        {
          name = "danieladov";
          url = "https://raw.githubusercontent.com/danieladov/JellyfinPluginManifest/master/manifest.json";
          enabled = true;
        }
        {
          name = "jellyfin-unstable";
          url = "https://repo.jellyfin.org/files/plugin-unstable/manifest.json";
          enabled = true;
        }
        {
          name = "jellyfin-plugin-cinemamode";
          url = "https://raw.githubusercontent.com/CherryFloors/jellyfin-plugin-cinemamode/main/manifest.json";
          enabled = true;
        }
        {
          name = "jellyfin-plugin-sso";
          url = "https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json";
          enabled = true;
        }
        {
          name = "Intro skipper";
          url = "https://intro-skipper.org/manifest.json";
          enabled = true;
        }
        {
          name = "Jellyfin-Enhanced";
          url = "https://raw.githubusercontent.com/n00bcodr/jellyfin-plugins/main/10.11/manifest.json";
          enabled = true;
        }
        {
          name = "File Transformation";
          url = "https://www.iamparadox.dev/jellyfin/plugins/manifest.json";
          enabled = true;
        }
      ];

      # Cast receiver applications
      castReceiverApplications = [
        {
          id = "F007D354";
          name = "Stable";
        }
        {
          id = "6F511C87";
          name = "Unstable";
        }
      ];
    };
  };

  nixarr = {
    enable = true;
    mediaUsers = [ config.my.defaults.user ];
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    vpn = {
      enable = true;
      wgConf = config.sops.secrets.wg_conf.path;
      vpnTestService = {
        enable = true;
        port = 58403;
      };
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
      extraSettings =
{
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
    jellyseerr.enable = true;

    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    sonarr.enable = true;
    readarr.enable = true;
    recyclarr = {
      enable = true;
      configFile = ./recyclarr.yaml;
    };
  };

  systemd.services = (
    lib.genAttrs servicesWithMediaAccess (_serviceName: {
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
    })
  );


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
