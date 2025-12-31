{
  pkgs,
  ...
}: {
  # Deluge user and group
  users.users.deluge = {
    isSystemUser = true;
    group = "deluge";
    extraGroups = [
      "users"
      "media"
    ];
  };

  users.groups.deluge = {};

  # Deluge daemon running in VPN namespace
  systemd.services.deluged = {
    description = "Deluge BitTorrent Daemon";
    after = ["wg.service"];
    requires = ["wg.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      User = "deluge";
      Group = "deluge";
      UMask = "0002";
      NetworkNamespacePath = "/run/netns/wg";
      BindReadOnlyPaths = [
        "/etc/netns/wg/resolv.conf:/etc/resolv.conf:norbind"
      ];
      ExecStart = "${pkgs.deluge}/bin/deluged -d -c /var/lib/deluge/.config/deluge -L warning -l /var/lib/deluge/deluged.log";
      Restart = "on-failure";

      # Hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      DevicePolicy = "closed";
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      LockPersonality = true;

      # Read/write access to state and download directories
      ReadWritePaths = [
        "/var/lib/deluge"
        "/data/Downloads"
        "/data/media"
      ];
    };
  };

  # Deluge web UI (runs in root namespace, connects to daemon via proxy)
  systemd.services.deluge-web = {
    description = "Deluge BitTorrent Web UI";
    after = ["deluged.service" "proxy-to-deluge-daemon.service"];
    requires = ["deluged.service" "proxy-to-deluge-daemon.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      User = "deluge";
      Group = "deluge";
      UMask = "0002";
      ExecStart = "${pkgs.deluge}/bin/deluge-web -c /var/lib/deluge/.config/deluge -L warning -l /var/lib/deluge/deluge-web.log";
      Restart = "on-failure";

      # Hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      DevicePolicy = "closed";
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      LockPersonality = true;

      # Read/write access to state directory
      ReadWritePaths = [
        "/var/lib/deluge"
      ];
    };
  };

  # Socket for daemon proxy
  systemd.sockets.proxy-to-deluge-daemon = {
    description = "Socket for Deluge daemon proxy";
    wantedBy = ["sockets.target"];
    requires = ["deluged.service"];
    socketConfig = {
      ListenStream = "127.0.0.1:58846";
    };
  };

  # Proxy service to connect web UI to daemon in VPN namespace
  systemd.services.proxy-to-deluge-daemon = {
    description = "Proxy to Deluge daemon in VPN namespace";
    after = ["deluged.service"];
    requires = ["deluged.service"];

    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:58846";
      NetworkNamespacePath = "/run/netns/wg";
      PrivateNetwork = true;
    };
  };

  # Create state and download directories
  systemd.tmpfiles.rules = [
    "d /var/lib/deluge 775 deluge deluge -"
    "d /var/lib/deluge/.config 775 deluge deluge -"
    "d /var/lib/deluge/.config/deluge 775 deluge deluge -"
    "d /data/media/.state/nixarr/deluge 775 deluge deluge -"
  ];

  # Firewall rules for web UI (8112) and peer port (to be configured in Deluge)
  networking.firewall.allowedTCPPorts = [
    8112 # Deluge web UI
  ];

  # Install Deluge package
  environment.systemPackages = with pkgs; [
    deluge
  ];
}
