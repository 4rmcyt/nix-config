{
  config,
  lib,
  ...
}: let
  root = "/data/Downloads";
  # Only arr-managed categories: a torrent there without a library hardlink is an upgraded/deleted leftover.
  arrCategories = ["tv-sonarr" "radarr"];
in {
  sops.templates."qbit-manage.env" = {
    content = "QBIT_PASS=${config.sops.placeholder.qbittorrent_password}\n";
    owner = "qbit-manage";
    restartUnits = ["qbit-manage.service"];
  };

  services.qbit-manage = {
    enable = true;
    group = "media";
    environmentFile = config.sops.templates."qbit-manage.env".path;

    commands = {
      schedule = 30;
      startupDelay = 60;
      tagNoHardLinks = true;
      shareLimits = true;
    };

    settings = {
      # Runs inside the wg netns: the host-side :8081 proxy fails qBittorrent's Host-port check.
      qbt = {
        host = "127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
        user = config.services.qbittorrent.serverConfig.Preferences.WebUI.Username;
        pass = "!ENV QBIT_PASS";
      };

      directory = {
        root_dir = root;
        recycle_bin = "${root}/.RecycleBin";
      };

      cat = lib.genAttrs ["audiobooks" "courses" "games" "kapowarr" "lidarr" "radarr" "tv-sonarr"] (c: "${root}/${c}");
      tracker = {};

      nohardlinks = lib.genAttrs arrCategories (_: {ignore_root_dir = true;});

      share_limits = {
        noHL = {
          priority = 1;
          include_all_tags = ["noHL"];
          categories = arrCategories;
          # Grace period so a not-yet-imported download isn't reaped before Sonarr/Radarr hardlink it.
          max_seeding_time = "1d";
          cleanup = true;
          share_limit_action = "Stop";
        };
        # Imported (hardlinked) arr torrents: seed to ratio 3, then drop; the library copy survives via its hardlink.
        imported = {
          priority = 2;
          categories = arrCategories;
          max_ratio = 3.0;
          cleanup = true;
          share_limit_action = "Stop";
        };
        default = {
          priority = 999;
          max_ratio = -1;
          max_seeding_time = -1;
          cleanup = false;
        };
      };

      recyclebin = {
        enabled = true;
        empty_after_x_days = 1;
        save_torrents = false;
      };
    };
  };

  systemd.services.qbit-manage = {
    after = ["data.mount" "wg.service" "qbittorrent.service"];
    requires = ["data.mount" "wg.service"];
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/wg";
      UMask = "0002";

      ProtectSystem = lib.mkForce "strict";
      ReadWritePaths = [root];
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHostname = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      RestrictNamespaces = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      # Upstream's per-line "~CAP_X" entries OR into the full set; no caps needed at all.
      CapabilityBoundingSet = lib.mkForce "";
      SystemCallFilter = lib.mkForce ["@system-service" "~@privileged @resources"];
      SystemCallErrorNumber = "EPERM";
      # Web server is disabled: no listening sockets at all.
      SocketBindDeny = lib.mkForce "any";
      # PrivateUsers deliberately NOT set: a new userns can't join a netns owned by the init userns.
    };
  };
}
