{
  pkgs,
  lib,
  ...
}: {
  services.qbittorrent = {
    enable = true;
    user = "qbittorrent";
    group = "media";
    webuiPort = 8080;
    torrentingPort = 63998;
    openFirewall = true;

    serverConfig = {
      Preferences = {
        Downloads = {
          SavePath = "/data/Downloads";
          TorrentExportDir = "/data/Downloads/torrents";
          TempPath = "/data/Downloads/.incomplete";
          PreAllocation = true;
          UseIncompleteExtension = true;
        };
        Queueing = {
          QueueingEnabled = true;
          MaxActiveDownloads = 8;
          MaxActiveTorrents = -1;
          MaxActiveUploads = -1;
        };
        IPFilter = {
          Enabled = true;
          FilterTracker = true;
          File = "/data/media/.state/nixarr/qbittorrent/ipfilter.p2p";
        };
        Connection = {
          GlobalMaxConnections = 500;
          GlobalMaxUploads = 50;
          MaxConnections = 100;
          MaxUploads = 8;
        };
        WebUI = {
          LocalHostAuth = false;
          AuthSubnetWhitelistEnabled = true;
          AuthSubnetWhitelist = "10.0.0.0/8,127.0.0.1/32,192.168.0.0/16";
        };
      };
      BitTorrent.Session = {
        Port = 63998;
        UPnP = false;
        GlobalDLSpeedLimit = -1;
        GlobalUPSpeedLimit = -1;
        DiskCacheSize = 1024;
        DiskCacheTTL = 60;
        UseOSCache = false;
        AnnounceToAllTrackers = true;
        AnnounceToAllTiers = true;
        ReannounceWhenAddressChanged = true;
        AsyncIOThreads = 10;
        HashingThreads = 2;
        MaxRatioEnforcement = true;
        MaxRatioAction = 0;
        AddTrackersEnabled = true;
        AddTrackersFromURLEnabled = true;
        AdditionalTrackersURL = "https://newtrackon.com/api/stable";
      };
    };
  };

  systemd.services.qbittorrent-blocklist-update = {
    description = "Update qBittorrent IP blocklist";
    after = [
      "network.target"
      "wg.service"
    ];
    startAt = "daily";
    path = with pkgs; [
      curl
      gnugrep
      util-linux
    ];
    script = ''
      set -euo pipefail
      STATE_DIR="/data/media/.state/nixarr/qbittorrent"
      curl -sSLf "https://raw.githubusercontent.com/Naunter/BT_BlockLists/refs/heads/master/bt_blocklists" \
        | grep -E '^.+:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' \
        > "$STATE_DIR/ipfilter.p2p"
      chown qbittorrent:media "$STATE_DIR/ipfilter.p2p"
      chmod 644 "$STATE_DIR/ipfilter.p2p"
      nsenter --net=/run/netns/wg curl -s -X POST "http://localhost:8080/api/v2/app/setPreferences" \
        --data "json={\"ip_filter_enabled\":false}"
      nsenter --net=/run/netns/wg curl -s -X POST "http://localhost:8080/api/v2/app/setPreferences" \
        --data "json={\"ip_filter_enabled\":true}"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # Override qBittorrent service to run in VPN namespace
  systemd.services.qbittorrent = {
    after = ["wg.service"];
    requires = ["wg.service"];
    serviceConfig = {
      # Clear BindPaths from parent nixarr config - they conflict with NetworkNamespacePath
      BindPaths = lib.mkForce [];
      NetworkNamespacePath = "/run/netns/wg";
      BindReadOnlyPaths = lib.mkForce [
        "/etc/netns/wg/resolv.conf:/etc/resolv.conf:norbind"
      ];
      RestrictNamespaces = lib.mkForce false;
      PrivateNetwork = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      Restart = lib.mkForce "always";
      RestartSec = "10s";
      UMask = "0002";
    };
  };

  # Proxy to expose qBittorrent WebUI from VPN namespace to host network
  systemd.sockets.proxy-to-qbittorrent = {
    description = "Socket for qBittorrent proxy";
    wantedBy = ["sockets.target"];
    requires = ["qbittorrent.service"];
    socketConfig.ListenStream = "8081";
  };

  systemd.services.proxy-to-qbittorrent = {
    description = "Proxy to qBittorrent in VPN namespace";
    after = ["qbittorrent.service"];
    requires = ["qbittorrent.service"];
    serviceConfig.ExecStart = "${pkgs.util-linux}/bin/nsenter --net=/run/netns/wg ${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:8080";
  };

  systemd.services.qbittorrent-categories = {
    description = "Write qBittorrent categories.json";
    before = ["qbittorrent.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "qbittorrent";
      Group = "media";
    };
    script = ''
      cfg=/var/lib/qBittorrent/qBittorrent/config/categories.json
      mkdir -p "$(dirname "$cfg")"
      cat > "$cfg" <<'EOF'
{
    "audiobooks": {
        "save_path": "/data/Downloads/audiobooks"
    },
    "lidarr": {
        "save_path": "/data/Downloads/lidarr"
    },
    "radarr": {
        "save_path": "/data/Downloads/radarr"
    },
    "tv-sonarr": {
        "save_path": "/data/Downloads/tv-sonarr"
    }
}
EOF
      chmod 600 "$cfg"
    '';
  };

  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/qbittorrent 775 qbittorrent media -"
    "d /data/Downloads/torrents 775 qbittorrent media -"
  ];
}
