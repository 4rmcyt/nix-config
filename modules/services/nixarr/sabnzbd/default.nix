{
  pkgs,
  lib,
  ...
}: {
  users.users.sabnzbd = {
    uid = lib.mkForce 961;
    extraGroups = [
      "users"
      "media"
    ];
  };

  users.groups.sabnzbd.gid = lib.mkForce 961;

  services.sabnzbd = {
    enable = true;
    user = "sabnzbd";
    group = "sabnzbd";
  };

  # Override SABnzbd service to run in VPN namespace
  systemd.services.sabnzbd = {
    after = ["wg.service"];
    requires = ["wg.service"];

    # Configure SABnzbd to use port 8090 and proper directories
    preStart = ''
      CONFIG_FILE=/var/lib/sabnzbd/sabnzbd.ini
      if [ -f "$CONFIG_FILE" ]; then
        # Set port to 8090 to avoid conflict with qBittorrent
        ${pkgs.gnused}/bin/sed -i 's|^port = .*|port = 8090|' "$CONFIG_FILE"
        ${pkgs.gnused}/bin/sed -i 's|^download_dir = .*|download_dir = /data/Downloads/usenet/incomplete|' "$CONFIG_FILE"
        ${pkgs.gnused}/bin/sed -i 's|^complete_dir = .*|complete_dir = /data/Downloads/usenet/complete|' "$CONFIG_FILE"
      fi
    '';

    serviceConfig = {
      # VPN namespace configuration
      NetworkNamespacePath = "/run/netns/wg";
      BindReadOnlyPaths = lib.mkForce [
        "/etc/netns/wg/resolv.conf:/etc/resolv.conf:norbind"
      ];

      # SABnzbd needs access to download directories
      ReadWritePaths = [
        "/data/Downloads"
        "/data/Downloads/usenet"
        "/data/Downloads/usenet/incomplete"
        "/data/Downloads/usenet/complete"
      ];

      # Run in foreground mode for namespace compatibility (daemon mode doesn't work in namespaces)
      Type = lib.mkForce "simple";
      ExecStart = lib.mkForce "${pkgs.sabnzbd}/bin/sabnzbd -f /var/lib/sabnzbd -s 0.0.0.0:8090 --browser 0";

      # Essential overrides for namespace compatibility
      RestrictNamespaces = lib.mkForce false;
      PrivateNetwork = lib.mkForce false;
      PrivateUsers = lib.mkForce false;

      # Service management
      Restart = lib.mkForce "always";
      RestartSec = "10s";
    };
  };

  # Socket for SABnzbd proxy (allows access from host network on port 8083)
  systemd.sockets.proxy-to-sabnzbd = {
    description = "Socket for SABnzbd proxy";
    wantedBy = ["sockets.target"];
    requires = ["sabnzbd.service"];
    socketConfig = {
      ListenStream = "8083"; # Listen on port 8083 on host (8082 already in use)
    };
  };

  # Proxy service to connect to SABnzbd in VPN namespace (on port 8090)
  systemd.services.proxy-to-sabnzbd = {
    description = "Proxy to SABnzbd in VPN namespace";
    after = ["sabnzbd.service"];
    requires = ["sabnzbd.service"];

    serviceConfig = {
      # Enter VPN namespace and proxy to SABnzbd on port 8090 (different from qBittorrent's 8080)
      ExecStart = "${pkgs.util-linux}/bin/nsenter --net=/run/netns/wg ${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:8090";
    };
  };

  # Create additional directories
  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/sabnzbd 775 sabnzbd sabnzbd -"
    "d /data/Downloads/usenet 775 sabnzbd media -"
    "d /data/Downloads/usenet/incomplete 775 sabnzbd media -"
    "d /data/Downloads/usenet/complete 775 sabnzbd media -"
  ];
}
