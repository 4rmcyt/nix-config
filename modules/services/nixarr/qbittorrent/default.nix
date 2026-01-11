{
  pkgs,
  lib,
  ...
}: {
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
    port = 8080;
    openFirewall = false;
  };

  # Override qBittorrent service to run in VPN namespace
  systemd.services.qbittorrent = {
    after = ["wg.service"];
    requires = ["wg.service"];

    serviceConfig = {
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
      Restart = lib.mkForce "always";
      RestartSec = "10s";
    };
  };

  # Socket for qBittorrent proxy (allows access from host network)
  systemd.sockets.proxy-to-qbittorrent = {
    description = "Socket for qBittorrent proxy";
    wantedBy = ["sockets.target"];
    requires = ["qbittorrent.service"];
    socketConfig = {
      ListenStream = "127.0.0.1:8080";
    };
  };

  # Proxy service to connect to qBittorrent in VPN namespace
  systemd.services.proxy-to-qbittorrent = {
    description = "Proxy to qBittorrent in VPN namespace";
    after = ["qbittorrent.service"];
    requires = ["qbittorrent.service"];

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
