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
      BindReadOnlyPaths = [
        "/etc/netns/wg/resolv.conf:/etc/resolv.conf:norbind"
      ];

      # Read/write access to state and download directories
      ReadWritePaths = [
        "/var/lib/qbittorrent"
        "/data/Downloads"
        "/data/media"
      ];

      # Adjusted hardening for network namespace compatibility
      # Network & Namespace settings
      RestrictNamespaces = lib.mkForce false;  # Required for NetworkNamespacePath
      PrivateNetwork = lib.mkForce false;      # Must be false when using NetworkNamespacePath

      # Filesystem protection (adjusted for data access)
      ProtectSystem = lib.mkForce "strict";    # Protect /usr /boot /efi but allow /etc writes via BindReadOnlyPaths
      ProtectHome = lib.mkForce "tmpfs";       # Mount empty tmpfs over /home but allow explicit paths
      ReadOnlyPaths = [ "/etc" ];              # Make /etc read-only except for our bind mounts

      # User/Device isolation
      PrivateUsers = lib.mkForce false;        # Required for namespace operations
      PrivateDevices = lib.mkForce true;       # Can be enabled - doesn't need device access
      PrivateTmp = lib.mkForce true;           # Isolate /tmp (note: qbittorrent module sets this to false, we override)

      # Process protection
      NoNewPrivileges = lib.mkForce true;
      ProtectProc = lib.mkForce "invisible";
      ProcSubset = lib.mkForce "pid";

      # Kernel protection
      ProtectKernelTunables = lib.mkForce true;
      ProtectKernelModules = lib.mkForce true;
      ProtectKernelLogs = lib.mkForce true;
      ProtectClock = lib.mkForce true;
      ProtectControlGroups = lib.mkForce true;
      ProtectHostname = lib.mkForce true;

      # System call restrictions
      SystemCallArchitectures = lib.mkForce "native";
      SystemCallFilter = lib.mkForce [ "@system-service" "~@privileged" "~@resources" ];

      # Address family restrictions
      RestrictAddressFamilies = lib.mkForce [ "AF_INET" "AF_INET6" "AF_NETLINK" ];

      # Other restrictions
      RestrictRealtime = lib.mkForce true;
      RestrictSUIDSGID = lib.mkForce true;
      LockPersonality = lib.mkForce true;
      MemoryDenyWriteExecute = lib.mkForce true;
      RemoveIPC = lib.mkForce true;

      # Capabilities
      CapabilityBoundingSet = lib.mkForce "";
      AmbientCapabilities = lib.mkForce "";

      # Service management
      Restart = lib.mkForce "always";
      RestartSec = "10s";
    };
  };

  # Socket for qBittorrent proxy (allows access from host network)
  systemd.sockets.proxy-to-qbittorrent = {
    description = "Socket for qBittorrent proxy";
    wantedBy = [ "sockets.target" ];
    requires = [ "qbittorrent.service" ];
    socketConfig = {
      ListenStream = "127.0.0.1:8080";
    };
  };

  # Proxy service to connect to qBittorrent in VPN namespace
  systemd.services.proxy-to-qbittorrent = {
    description = "Proxy to qBittorrent in VPN namespace";
    after = [ "qbittorrent.service" ];
    requires = [ "qbittorrent.service" ];

    serviceConfig = {
      ExecStart = "${pkgs.util-linux}/bin/nsenter --net=/run/netns/wg ${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:8080";
    };
  };

  # Create additional directories
  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/qbittorrent 775 qbittorrent qbittorrent -"
    "d /data/Downloads/torrents 775 qbittorrent media -"
  ];
}
