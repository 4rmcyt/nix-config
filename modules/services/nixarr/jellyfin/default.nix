{ lib, ... }: {
  # Jellyfin declarative configuration using nixos-jellyfin module
  services.jellyfin = {
    enable = true;

    settings = {
      # System configuration (from base-app-config.nix and server-config.nix)
      system = {
        # Base configuration
        isStartupWizardCompleted = true;
        cachePath = "/data/media/.state/nixarr/jellyfin/cache";
        logFileRetentionDays = 3;

        # Server identity
        serverName = "homeserver";
        displayLanguage = "en-US";

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
        corsHosts = ["*"];
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
            enable = true;
          }
          {
            name = "danieladov";
            url = "https://raw.githubusercontent.com/danieladov/JellyfinPluginManifest/master/manifest.json";
            enable = true;
          }
          {
            name = "jellyfin-unstable";
            url = "https://repo.jellyfin.org/files/plugin-unstable/manifest.json";
            enable = true;
          }
          {
            name = "jellyfin-plugin-cinemamode";
            url = "https://raw.githubusercontent.com/CherryFloors/jellyfin-plugin-cinemamode/main/manifest.json";
            enable = true;
          }
          {
            name = "jellyfin-plugin-sso";
            url = "https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json";
            enable = true;
          }
          {
            name = "Intro skipper";
            url = "https://intro-skipper.org/manifest.json";
            enable = true;
          }
          {
            name = "Jellyfin-Enhanced";
            url = "https://raw.githubusercontent.com/n00bcodr/jellyfin-plugins/main/10.11/manifest.json";
            enable = true;
          }
          {
            name = "File Transformation";
            url = "https://www.iamparadox.dev/jellyfin/plugins/manifest.json";
            enable = true;
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

      # Encoding configuration (from encoding-options.nix)
      encoding = {
        # Hardware acceleration (VAAPI for Intel/AMD)
        hardwareAccelerationType = "vaapi";
        vaapiDevice = "/dev/dri/renderD128";
        enableHardwareEncoding = true;
        preferSystemNativeHwDecoder = true;
        hardwareDecodingCodecs = ["h264" "hevc" "mpeg2video" "vp8" "vp9" "vc1"];

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
        allowOnDemandMetadataBasedKeyframeExtractionForExtensions = ["mkv"];
      };

      # Metadata configuration (from metadata-config.nix)
      metadata = {
        useFileCreationTimeForDateAdded = true;
      };
    };
  };

  # Fix nixos-jellyfin module's preStart chmod issue with read-only nix store symlinks
  systemd.services.jellyfin.preStart = lib.mkForce "";
}
