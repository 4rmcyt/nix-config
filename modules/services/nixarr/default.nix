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

  # Pinned explicitly: oci-containers interpolate PUID/PGID at eval time, before
  # dynamically-allocated uids exist. radarr/sonarr excluded (their modules already
  # pin uids); their GIDs are forced below since nixpkgs' ids no longer match
  # homeserver's actual /etc/group.
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
    ./trawl
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
    # radarr/sonarr users/groups come from their own nixpkgs service modules.
    {
      radarr.extraGroups = ["users" "media"];
      # sonarr-sync-config runs as sonarr:sonarr and reads sonarr.api-key (group sonarr-api).
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
    # Default ffmpeg-full disables libfdk-aac, breaking xHE-AAC (M4B) audiobook scanning.
    audiobookshelf.package = pkgs.audiobookshelf.override {
      ffmpeg_8-full = pkgs.ffmpeg_8-full.override {withUnfree = true;};
    };
    jellyfin.enable = false; # handled by ./jellyfin
    lidarr.enable = true;

    # Upstream bug: pname "nixarr" vs pyproject.toml's "nixarr_py" fails nixpkgs'
    # pythonMetadataCheckPhase; skipping only skips the version-string check.
    nixarr-py.package =
      (pkgs.callPackage "${inputs.nixarr}/nixarr/lib/nixarr-py" {
        jellyfin = config.services.jellyfin.package;
      })
      .overrideAttrs (_: {
        dontCheckPythonMetadata = true;
      });
  };

  systemd.services = lib.mkMerge [
    # nixarr passes an absolute path to StateDirectory=, which systemd rejects; the
    # dir already exists via tmpfiles so clearing it is safe.
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
    # sonarr/radarr still carry the full default CapabilityBoundingSet, unlike
    # bazarr/lidarr/prowlarr here — same gap, not yet closed for them.
    # ProtectSystem left alone for bazarr: its ffmpeg subtitle burn-in needs
    # read/write to the media library outside dataDir, outside BindPaths above.
    {
      bazarr.serviceConfig = {
        CapabilityBoundingSet = lib.mkForce "";
        NoNewPrivileges = lib.mkDefault true;
      };
      # No MemoryDenyWriteExecute: lidarr is .NET like radarr/sonarr, JIT needs W+X memory.
      lidarr.serviceConfig = {
        CapabilityBoundingSet = lib.mkForce "";
        NoNewPrivileges = lib.mkDefault true;
        ProtectSystem = "full";
        PrivateMounts = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        LockPersonality = true;
        RestrictRealtime = true;
        ProtectClock = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_NETLINK" "AF_UNIX"];
        SocketBindDeny = ["ipv4:udp" "ipv6:udp"];
        # A Nix list of "~@group:EPERM" strings renders as one SystemCallFilter= line
        # per element, but systemd only honors the leading "~" on the first line —
        # set SystemCallErrorNumber once and pass a single "~"-prefixed string instead.
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = "~@aio @chown @clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @pkey @privileged @raw-io @reboot @sandbox @setuid @swap";
      };
      # No MemoryDenyWriteExecute: Node.js/V8 JIT needs W+X memory (same class as
      # the Go alloy.service incident).
      audiobookshelf.serviceConfig = {
        CapabilityBoundingSet = lib.mkForce "";
        LockPersonality = true;
        RestrictAddressFamilies = ["AF_INET" "AF_NETLINK"];
        SocketBindDeny = ["ipv4:udp" "ipv6:tcp" "ipv6:udp"];
        # Same SystemCallFilter merge quirk as lidarr above — single "~"-prefixed string.
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = "~@aio @chown @clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @pkey @privileged @raw-io @reboot @resources @sandbox @setuid @swap";
      };
    }
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
    # prowlarr/radarr/bazarr dataDir tmpfiles rules are managed by their own nixpkgs
    # service modules — a rule here would conflict. sonarr's isn't (custom dataDir),
    # so it still needs one below.
    "d /data/media/.state/nixarr/sonarr 775 sonarr sonarr -"

    # mode "-": Z can't distinguish files from dirs, so a numeric mode here would
    # wrongly apply directory bits (setgid, exec) to files too.
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
    config.my.network.ports.seerr
    config.my.network.ports.bazarr
    config.my.network.ports.radarr
    config.my.network.ports.jellyfin
    config.my.network.ports.lidarr
    8920 # Jellyfin HTTPS
    config.my.network.ports.sonarr
    config.my.network.ports.audiobookshelf
    config.my.network.ports.prowlarr
  ];
  networking.firewall.allowedUDPPorts = [
    1900 # DLNA/UPnP
    7359 # Jellyfin auto-discovery
  ];
}
