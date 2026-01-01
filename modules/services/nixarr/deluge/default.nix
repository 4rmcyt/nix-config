{
  pkgs,
  lib,
  config,
  ...
}: {
  users.users.deluge = {
    isSystemUser = true;
    group = lib.mkForce "deluge";
    extraGroups = [
      "users"
      "media"
    ];
  };

  users.groups.deluge = {};

  sops.secrets.deluge-accounts = {
    sopsFile = ../../../../secrets/deluge.yaml;
    key = "auth";
    owner = config.users.users.deluge.name;
    group = config.users.groups.deluge.name;
    mode = "0600";
  };

  services.deluge = {
    enable = true;
    declarative = true;
    authFile = config.sops.secrets.deluge-accounts.path;
    config = {
      enabled_plugins = ["Label"];
      torrentfiles_location = "/data/Downloads/torrents";
      download_location = "/data/Downloads";
      dont_count_slow_torrents = true;
      max_active_seeding = 5;
      max_active_limit = -1;
      max_active_downloading = 8;
      max_connections_global = -1;
      allow_remote = true;
      daemon_port = 58846;
      random_port = false;
      listen_ports = [
        63998
      ];
      random_outgoing_ports = false;
    };
    # Publicly opens listen_ports only
    openFirewall = true;
    web = {
      enable = true;
      port = 8112;
    };
  };

  # Override deluged service to run in VPN namespace
  systemd.services.deluged = {
    after = ["wg.service"];
    requires = ["wg.service"];

    serviceConfig = {
      NetworkNamespacePath = "/run/netns/wg";
      BindReadOnlyPaths = [
        "/etc/netns/wg/resolv.conf:/etc/resolv.conf:norbind"
      ];
      # Read/write access to state and download directories
      ReadWritePaths = [
        "/var/lib/deluge"
        "/data/Downloads"
        "/data/media"
      ];
    };
  };

  # Socket for daemon proxy (web UI connects to this instead of daemon directly)
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
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 192.168.15.1:58846";
    };
  };

  # Override deluge-web service to depend on proxy
  systemd.services.deluge-web = {
    after = [
      "deluged.service"
      "proxy-to-deluge-daemon.service"
    ];
    requires = [
      "deluged.service"
      "proxy-to-deluge-daemon.service"
    ];
  };

  # Create additional directories
  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/deluge 775 deluge deluge -"
  ];
}
