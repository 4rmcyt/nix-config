{
  config,
  pkgs,
  lib,
  ...
}: let
  # qBittorrent's own WebUI, reachable only inside the VPN netns — distinct
  # from config.my.network.ports.qb (the host-side proxy socket below).
  webuiPort = 8080;
  confFile = "${config.services.qbittorrent.profileDir}/qBittorrent/config/qBittorrent.conf";

  # Same format as qBittorrent's Utils::Password::PBKDF2::generate: sha512, 100k iters, 16-byte salt.
  injectPassword = pkgs.writers.writePython3 "qbittorrent-inject-password" {} ''
    import base64
    import hashlib
    import os
    import sys

    conf, secret = sys.argv[1], sys.argv[2]
    with open(secret, "rb") as f:
        pw = f.read().rstrip(b"\n")
    salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac("sha512", pw, salt, 100000)
    b64 = base64.b64encode
    value = "@ByteArray(%s:%s)" % (b64(salt).decode(), b64(dk).decode())
    line = 'WebUI\\Password_PBKDF2="%s"\n' % value
    with open(conf) as f:
        lines = f.readlines()
    idx = lines.index("[Preferences]\n") + 1
    lines.insert(idx, line)
    with open(conf, "w") as f:
        f.writelines(lines)
  '';
in {
  sops.secrets.qbittorrent_password = {
    sopsFile = ../../../../secrets/medialib.yaml;
    owner = "qbittorrent";
    group = "media";
    mode = "0400";
    restartUnits = ["qbittorrent.service"];
  };

  services.qbittorrent = {
    enable = true;
    user = "qbittorrent";
    group = "media";
    inherit webuiPort;
    torrentingPort = 63998;
    # Runs in the wg netns: host-side 8080 is dead; torrent port is handled by modules/networking/wireguard.
    openFirewall = false;

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
        Connection = {
          GlobalMaxConnections = 500;
          GlobalMaxUploads = 50;
          MaxConnections = 100;
          MaxUploads = 8;
        };
        # Username only; the password hash is injected at start from sops (see injectPassword).
        WebUI.Username = "admin";
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
        AddTrackersEnabled = true;
        AddTrackersFromURLEnabled = true;
        AdditionalTrackersURL = "https://newtrackon.com/api/stable";
      };
    };
  };

  systemd.services.qbittorrent = {
    after = ["wg.service"];
    requires = ["wg.service"];
    serviceConfig = {
      # mkAfter: must run after the module's ExecStartPre that installs the generated config.
      ExecStartPre = lib.mkAfter ["${injectPassword} ${confFile} ${config.sops.secrets.qbittorrent_password.path}"];
      # Parent nixarr config's BindPaths conflict with NetworkNamespacePath.
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

      RestrictAddressFamilies = lib.mkForce ["AF_INET" "AF_INET6" "AF_NETLINK"];
    };
  };

  systemd.sockets.proxy-to-qbittorrent = {
    description = "Socket for qBittorrent proxy";
    wantedBy = ["sockets.target"];
    requires = ["qbittorrent.service"];
    socketConfig.ListenStream = toString config.my.network.ports.qb;
  };

  systemd.services.proxy-to-qbittorrent = {
    description = "Proxy to qBittorrent in VPN namespace";
    after = ["qbittorrent.service"];
    requires = ["qbittorrent.service"];
    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString webuiPort}";
      # systemd joins the netns before exec, so no root/CAP_SYS_ADMIN for nsenter; the socket unit stays in the host netns.
      NetworkNamespacePath = "/run/netns/wg";
      DynamicUser = true;
      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectClock = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      ProtectHostname = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = ["@system-service" "~@privileged" "~@resources"];
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
      UMask = "0077";
      # PrivateUsers deliberately NOT set: a new userns can't join a netns owned by the init userns.
    };
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
          "kapowarr": {
              "save_path": "/data/Downloads/kapowarr"
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
