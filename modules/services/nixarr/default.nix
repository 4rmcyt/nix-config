{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  servicesWithMediaAccess = [
    "audiobookshelf"
    "lidarr"
    "qbittorrent"
  ];

  # Pinned explicitly (not left to dynamic useradd allocation) because
  # oci-containers PUID/PGID env vars are interpolated at Nix eval time —
  # config.users.users.<name>.uid is null until activation otherwise,
  # so ${toString ...} silently renders as an empty string.
  #
  # radarr/sonarr users are NOT here: their nixpkgs service modules already
  # create users.users.{radarr,sonarr} pinned to config.ids.uids.* -- they
  # only need extraGroups added, done separately below. Their group GIDs
  # ARE overridden below (lib.mkForce) because nixpkgs pins them to
  # config.ids.gids.{radarr,sonarr} (274/275), which no longer matches the
  # GIDs actually present in /etc/group on homeserver (970/975, from before
  # these services were declared here); without the override, activation
  # just warns ("not applying GID change") and leaves /etc/group untouched
  # anyway, so this documents reality instead of fighting it every rebuild.
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
    recyclarr = {
      uid = 269;
      gid = 269;
    };
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

  users.users = lib.mkMerge [
    (lib.mapAttrs
      (name: ids: {
        isSystemUser = true;
        inherit (ids) uid;
        group = lib.mkForce name;
        extraGroups = ["users" "media"];
      })
      serviceIds)
    # radarr/sonarr users/groups are created by their own nixpkgs service
    # modules (services.radarr/services.sonarr) -- just add the extra group
    # memberships the media stack needs on top of that.
    {
      radarr.extraGroups = ["users" "media"];
      # sonarr-sync-config runs as sonarr:sonarr and reads sonarr.api-key (group sonarr-api)
      sonarr.extraGroups = ["users" "media" "sonarr-api"];
    }
  ];

  users.groups =
    lib.mapAttrs (_name: ids: {inherit (ids) gid;}) serviceIds
    // {
      radarr.gid = lib.mkForce 975;
      sonarr.gid = lib.mkForce 970;
    };

  environment.systemPackages = with pkgs; [
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
  ];

  systemd.tmpfiles.rules = [
    "d /data 770 root media -"
    "d /data/media 775 root media -"
    "d /data/Downloads 775 ${config.my.defaults.user} media -"

    "d /data/media/movies 2775 ${config.my.defaults.user} media -"
    "d /data/media/shows 2775 ${config.my.defaults.user} media -"
    "d /data/media/anime 2775 ${config.my.defaults.user} media -"
    "d /data/media/music 775 ${config.my.defaults.user} media -"
    "d /data/media/audiobooks 775 ${config.my.defaults.user} media -"
    "d /data/media/books 775 ${config.my.defaults.user} media -"
    "d /data/media/comics 2775 ${config.my.defaults.user} media -"
    "d /data/media/manga 2775 ${config.my.defaults.user} media -"

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
    # prowlarr's dataDir tmpfiles rule (bind-mount source dir) is now managed
    # by services.prowlarr itself -- a second rule here for the same path
    # would conflict with it.
    # radarr's dataDir tmpfiles rule is now managed by services.radarr itself
    # (unconditionally, mode 0700) -- a second rule here would conflict.
    # sonarr's is NOT auto-managed by services.sonarr for a custom dataDir
    # (only for its own default path), so its rule below is still needed.
    "d /data/media/.state/nixarr/sonarr 775 sonarr sonarr -"
    # bazarr's dataDir tmpfiles rule is now managed by services.bazarr itself
    # (nixpkgs' bazarr.nix module, mode 0700) -- a second rule here for the
    # same path would conflict with it.

    # mode "-" (unchanged): only owner/group are re-synced recursively, not mode —
    # forcing a numeric mode here would apply directory bits (setgid, exec) to
    # regular files too, since Z can't distinguish files from directories.
    # Correct file/dir mode for new content comes from each container's UMASK.
    "Z /data/media/movies - ${config.my.defaults.user} media -"
    "Z /data/media/shows - ${config.my.defaults.user} media -"
    "Z /data/media/anime - ${config.my.defaults.user} media -"
    "Z /data/media/music - ${config.my.defaults.user} media -"
    "Z /data/media/audiobooks - ${config.my.defaults.user} media -"
    "Z /data/media/books - ${config.my.defaults.user} media -"
    "Z /data/media/comics - ${config.my.defaults.user} media -"
    "Z /data/media/manga - ${config.my.defaults.user} media -"
    "Z /data/Downloads - ${config.my.defaults.user} media -"
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
