{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  servicesWithMediaAccess = [
    "audiobookshelf"
    "jellyfin"
    "lidarr"
    "qbittorrent"
  ];

  servicesWithScripts = [
    "lidarr"
  ];

  # Pinned explicitly (not left to dynamic useradd allocation) because
  # oci-containers PUID/PGID env vars are interpolated at Nix eval time —
  # config.users.users.<name>.uid is null until activation otherwise,
  # so ${toString ...} silently renders as an empty string.
  serviceIds = {
    audiobookshelf = {
      uid = 156;
      gid = 998;
    };
    bazarr = {
      uid = 232;
      gid = 995;
    };
    seerr = {
      uid = 262;
      gid = 250;
    };
    lidarr = {
      uid = 306;
      gid = 985;
    };
    prowlarr = {
      uid = 293;
      gid = 287;
    };
    radarr = {
      uid = 275;
      gid = 975;
    };
    sonarr = {
      uid = 274;
      gid = 970;
    };
    recyclarr = {
      uid = 269;
      gid = 269;
    };
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
in {
  imports = [
    ./bazarr
    ./byparr
    ./jellyfin
    ./kapowarr
    ./lazylibrarian
    ./prowlarr
    ./qbittorrent
    ./radarr
    ./recyclarr
    ./seerr
    ./sonarr
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
    radarr_api_key = {
      sopsFile = ../../../secrets/medialib.yaml;
      owner = "recyclarr";
      key = "radarr_api_key";
      group = "recyclarr";
      mode = "0440";
    };
    sonarr_api_key = {
      sopsFile = ../../../secrets/medialib.yaml;
      owner = "recyclarr";
      key = "sonarr_api_key";
      group = "recyclarr";
      mode = "0440";
    };
  };

  users.users =
    lib.mapAttrs
    (name: ids: {
      isSystemUser = true;
      inherit (ids) uid;
      group = lib.mkForce name;
      extraGroups =
        ["users" "media"]
        # sonarr-sync-config runs as sonarr:sonarr and reads sonarr.api-key (group sonarr-api)
        ++ lib.optional (name == "sonarr") "sonarr-api";
    })
    serviceIds;

  users.groups = lib.mapAttrs (_name: ids: {inherit (ids) gid;}) serviceIds;

  environment.systemPackages = with pkgs; [
    musicConverter
    shntool
    cuetools
  ];

  nixarr = {
    enable = true;
    mediaUsers = [config.my.defaults.user];
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    audiobookshelf.enable = true;
    jellyfin.enable = false; # Handled by ./jellyfin
    lidarr.enable = true;

    # Upstream bug: pname = "nixarr" but pyproject.toml declares name =
    # "nixarr_py", so nixpkgs' pythonMetadataCheckPhase can't find metadata
    # for "nixarr" and fails the build. Skip the check — it only verifies
    # the version string in pyproject.toml matches the derivation version.
    nixarr-py.package =
      (pkgs.callPackage "${inputs.nixarr}/nixarr/lib/nixarr-py" {
        jellyfin = config.nixarr.jellyfin.package;
      })
      .overrideAttrs (_: {
        dontCheckPythonMetadata = true;
      });
  };

  systemd.services = lib.mkMerge [
    # nixarr passes an absolute path to StateDirectory= which systemd rejects with a warning.
    # StateDirectory= must be relative. Clear it — the dir already exists via tmpfiles.
    {
      audiobookshelf.serviceConfig.StateDirectory = lib.mkForce "";
    }
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
        musicConverter
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

    "d /data/media/library 2775 root media -"

    "d /data/media/.state 770 root media -"
    "d /data/media/.state/nixarr 770 root media -"
    "d /data/media/.state/nixarr/seerr 775 seerr seerr -"
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
    5055 # seerr
    6767 # Bazarr
    7878 # Radarr
    8096 # Jellyfin HTTP
    8686 # Lidarr
    8920 # Jellyfin HTTPS
    8990 # Sonarr
    9292 # Audiobookshelf
    9696 # Prowlarr
  ];
  networking.firewall.allowedUDPPorts = [
    1900 # DLNA/UPnP
    7359 # Jellyfin auto-discovery
  ];
}
