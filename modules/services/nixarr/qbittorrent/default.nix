{
  pkgs,
  lib,
  ...
}: {
  users.users.qbittorrent = {
    home = "/data/media/.state/nixarr/qbittorrent";
    createHome = true;
    isSystemUser = true;
    extraGroups = [
      "users"
      "media"
    ];
  };

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
          PortRangeMin = 63998;
          GlobalDLSpeedLimit = 0;
          GlobalUPSpeedLimit = 0;
          GlobalMaxConnections = 500;
          GlobalMaxUploads = 50;
          MaxConnections = 100;
          MaxUploads = 8;
        };
        WebUI = {
          # Bypass authentication from localhost
          LocalHostAuth = false;
        };
      };
      BitTorrent = {
        Session = {
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
          AdditionalTrackers = "";
          AddTrackersFromURLEnabled = true;
          AdditionalTrackersURL = "https://newtrackon.com/api/stable";
        };
        State = {
          BannedIPs = "";
        };
      };
      Network = {
        Proxy = {
          Type = "None";
          Profiles = {
            BitTorrent = false;
            Misc = false;
            RSS = false;
          };
        };
      };
    };
  };

  systemd.services.qbittorrent-blocklist-update = {
    description = "Update qBittorrent IP blocklist and Tracker list";
    after = [
      "network.target"
      "wg.service"
    ];
    startAt = "daily";
    path = with pkgs; [
      curl
      gzip
      util-linux
    ];
    script = ''
      set -euo pipefail
      STATE_DIR="/data/media/.state/nixarr/qbittorrent"
      curl -sSL "https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz" | zcat > "$STATE_DIR/ipfilter.p2p"
      chown -R qbittorrent:media "$STATE_DIR"
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

      # VPN namespace configuration
      NetworkNamespacePath = "/run/netns/wg";
      BindReadOnlyPaths = lib.mkForce [
        "/etc/netns/wg/resolv.conf:/etc/resolv.conf:norbind"
      ];

      # Essential overrides for namespace compatibility
      RestrictNamespaces = lib.mkForce false;
      PrivateNetwork = lib.mkForce false;
      PrivateUsers = lib.mkForce false;

      # Service management
      Restart = lib.mkForce "always";
      RestartSec = "10s";
    };
  };

  # Socket for qBittorrent proxy (allows access from host network on port 8081)
  systemd.sockets.proxy-to-qbittorrent = {
    description = "Socket for qBittorrent proxy";
    wantedBy = ["sockets.target"];
    requires = ["qbittorrent.service"];
    socketConfig = {
      ListenStream = "8081"; # Listen on port 8081 on host
    };
  };

  # Proxy service to connect to qBittorrent in VPN namespace (on port 8080)
  systemd.services.proxy-to-qbittorrent = {
    description = "Proxy to qBittorrent in VPN namespace";
    after = ["qbittorrent.service"];
    requires = ["qbittorrent.service"];

    serviceConfig = {
      # Enter VPN namespace and proxy to qBittorrent on port 8080
      ExecStart = "${pkgs.util-linux}/bin/nsenter --net=/run/netns/wg ${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:8080";
    };
  };

  # Create additional directories
  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/qbittorrent 775 qbittorrent qbittorrent -"
    "d /data/Downloads/torrents 775 qbittorrent media -"
  ];
}
