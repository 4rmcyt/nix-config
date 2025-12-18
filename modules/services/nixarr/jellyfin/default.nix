{
  nixos-jellyfin,
  lib,
  pkgs,
  ...
}: {
  # imports = [
  #   nixos-jellyfin.nixosModules.default
  # ];

  users.users.jellyfin = {
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

  services.jellyfin = {
    enable = true;
    package = pkgs.jellyfin;
    ffmpegPackage = pkgs.jellyfin-ffmpeg;
    webPackage = pkgs.jellyfin-web;

    settings = {
      system = {
        serverName = "Jellyfin Homeserver";
        quickConnectAvailable = false;
        isStartupWizardCompleted = true;

        enableGroupingIntoCollections = false;
        enableExternalContentInSuggestions = false;

        metadataPath = "/data/media/.state/nixarr/jellyfin/data/metadata";
        cachePath = "/data/media/.state/nixarr/jellyfin/cache";

        pluginRepositories = [
          {
            name = "Jellyfin Stable";
            url = "https://repo.jellyfin.org/releases/plugin/manifest-stable.json";
          }
          {
            name = "Intro Skipper";
            url = "https://manifest.intro-skipper.org/manifest.json";
          }
          {
            name = "Merge Versions Plugin";
            url = "https://raw.githubusercontent.com/danieladov/JellyfinPluginManifest/master/manifest.json";
          }
          {
            name = "Meilisearch";
            url = "https://raw.githubusercontent.com/arnesacnussem/jellyfin-plugin-meilisearch/refs/heads/master/manifest.json";
          }
          {
            name = "Air Times";
            url = "https://raw.githubusercontent.com/apteryxxyz/jellyfin-plugin-airtimes/main/manifest.json";
          }
          {
            name = "InPlayerEpisodePreview";
            url = "https://raw.githubusercontent.com/Namo2/InPlayerEpisodePreview/master/manifest.json";
          }
          {
            name = "Streamyfin";
            url = "https://raw.githubusercontent.com/streamyfin/jellyfin-plugin-streamyfin/main/manifest.json";
          }
          {
            name = "danieladov";
            url = "https://raw.githubusercontent.com/danieladov/JellyfinPluginManifest/master/manifest.json";
          }
          {
            name = "jellyfin-unstable";
            url = "https://repo.jellyfin.org/files/plugin-unstable/manifest.json";
          }
          {
            name = "jellyfin-plugin-cinemamode";
            url = "https://raw.githubusercontent.com/CherryFloors/jellyfin-plugin-cinemamode/main/manifest.json";
          }
          {
            name = "jellyfin-plugin-sso";
            url = "https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json";
          }
          {
            name = "Intro skipper";
            url = "https://intro-skipper.org/manifest.json";
          }
          {
            name = "File Transformation";
            url = "https://www.iamparadox.dev/jellyfin/plugins/manifest.json";
          }
        ];

        enableSlowResponseWarning = false;
      };

      encoding = {
        hardwareAccelerationType = "vaapi";
        vaapiDevice = "/dev/dri/renderD128";
        enableHardwareEncoding = true;
        preferSystemNativeHwDecoder = true;
        hardwareDecodingCodecs = [
          "h264"
          "hevc"
          "mpeg2video"
          "mpeg4"
          "vc1"
          "vp8"
          "vp9"
        ];
        allowHevcEncoding = true;
        enableThrottling = true;
        enableTonemapping = true;
        tonemappingAlgorithm = "bt2390";
        tonemappingMode = "auto";
        tonemappingRange = "auto";
        tonemappingDesat = 0;
        tonemappingPeak = 100;
        tonemappingParam = 0;

        encodingThreadCount = 4;
        encoderPreset = "superfast";

        # Enable 10-bit codec support
        enableDecodingColorDepth10Hevc = true;
        enableDecodingColorDepth10Vp9 = true;

        # Intel low-power encoders
        enableIntelLowPowerH264HwEncoder = true;
        enableIntelLowPowerHevcHwEncoder = false;

        transcodingTempPath = "/data/media/.state/nixarr/jellyfin/cache/transcodes";
        maxMuxingQueueSize = 2048;
        throttleDelaySeconds = 180;
        enableSegmentDeletion = true;
        segmentKeepSeconds = 720;

        # Subtitle extraction
        enableSubtitleExtraction = true;
        enableFallbackFont = false;

        # Keyframe extraction
        allowOnDemandMetadataBasedKeyframeExtractionForExtensions = ["mkv"];
      };
    };
  };
}
