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
      enabled_plugins = [
        "Label"
        "Blocklist"
        "AutoRemovePlus"
      ];
      torrentfiles_location = "/data/Downloads/torrents";
      download_location = "/data/Downloads";
      pre_allocate_storage = true;
      dont_count_slow_torrents = true;
      max_active_seeding = -1;
      max_active_limit = -1;
      max_active_downloading = 8;
      max_connections_global = -1;
      max_connections_per_second = 150;
      max_half_open_connections = 100;
      max_download_speed = -1.0;
      max_upload_speed = -1.0;
      allow_remote = true;
      daemon_port = 58846;
      random_port = false;
      listen_ports = [
        63998
        63998
      ];
      random_outgoing_ports = false;
      enc_level = 2;
      enc_in_policy = 1;
      enc_out_policy = 1;
      upnp = false;
      natpmp = false;
      dht = true;
      peer_tos = "0x00";
      blocklist = {
        url = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
        check_after_days = 7;
        load_on_start = true;
      };
    };
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
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:58846";
      NetworkNamespacePath = "/run/netns/wg";
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
