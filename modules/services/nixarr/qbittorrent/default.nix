{
  pkgs,
  lib,
  ...
}:
{
  users.users.qbittorrent = {
    extraGroups = [
      "users"
      "media"
    ];
  };

  services.qbittorrent = {
    enable = true;
    user = "qbittorrent";
    group = "qbittorrent";
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
        BitTorrent = {
          Session = {
            Port = 63998;
            UPnP = false;
            GlobalDLSpeedLimit = -1;
            GlobalUPSpeedLimit = -1;
          };
        };
        Connection = {
          PortRangeMin = 63998;
          GlobalDLSpeedLimit = 0;
          GlobalUPSpeedLimit = 0;
        };
        WebUI = {
          # Bypass authentication from localhost
          LocalHostAuth = false;
        };
      };
    };
  };

  # Override qBittorrent service to run in VPN namespace
  systemd.services.qbittorrent = {
    after = [ "wg.service" ];
    requires = [ "wg.service" ];

    serviceConfig = {
      # Clear BindPaths from parent nixarr config - they conflict with NetworkNamespacePath
      BindPaths = lib.mkForce [ ];

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
    wantedBy = [ "sockets.target" ];
    requires = [ "qbittorrent.service" ];
    socketConfig = {
      ListenStream = "8081";  # Listen on port 8081 on host
    };
  };

  # Proxy service to connect to qBittorrent in VPN namespace (on port 8080)
  systemd.services.proxy-to-qbittorrent = {
    description = "Proxy to qBittorrent in VPN namespace";
    after = [ "qbittorrent.service" ];
    requires = [ "qbittorrent.service" ];

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
