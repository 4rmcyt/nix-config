{config, ...}: let
  port = toString config.my.network.ports.lazylibrarian;
in {
  virtualisation.oci-containers.containers.lazylibrarian = {
    autoStart = true;
    image = "lscr.io/linuxserver/lazylibrarian:latest";
    # Published ports are DNAT'd past the NixOS firewall: bind loopback (reverse proxy, prowlarr sync) + LAN IP only.
    ports = [
      "127.0.0.1:${port}:${port}"
      "${config.my.network.hosts.homeserver_lan}:${port}:${port}"
    ];
    extraOptions = [
      # PUID/PGID are set at runtime, not in the image passwd, so pin the range size instead of auto-estimating.
      "--userns=auto:size=65536"
      # Bridge DNS can't see the LAN split-horizon; reach qBittorrent via host Caddy, not the unauthenticated :8081 proxy.
      "--add-host=qb.${config.my.defaults.domain}:host-gateway"
      "--label=io.containers.autoupdate=registry"
      "--security-opt=no-new-privileges"
      # LinuxServer.io-style s6-overlay init needs these to chown /config and
      # setuid/setgid down to PUID/PGID at startup -- cap-drop=all alone
      # breaks the permission-drop step.
      "--cap-drop=all"
      "--cap-add=CHOWN"
      "--cap-add=DAC_OVERRIDE"
      "--cap-add=FOWNER"
      "--cap-add=KILL"
      "--cap-add=SETGID"
      "--cap-add=SETUID"
    ];
    environment = {
      PUID = "1000";
      PGID = toString config.users.groups.media.gid;
      TZ = config.my.defaults.timezone;
      DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg";
    };
    volumes = [
      "/data/media/.state/nixarr/lazylibrarian:/config:idmap"
      "/data/media/books:/books:idmap"
      "/data/Downloads/books:/downloads:idmap"
      "/data/media/audiobooks:/audiobooks:idmap"
      "/data/Downloads/audiobooks:/downloads-audiobooks:idmap"
    ];
  };

  systemd.services.podman-lazylibrarian = {
    after = ["data.mount"];
    requires = ["data.mount"];
  };

  # Torznab feeds come from Prowlarr on the host (host.containers.internal).
  networking.firewall.interfaces.podman0.allowedTCPPorts = [config.my.network.ports.prowlarr];

  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/lazylibrarian 775 ${config.my.defaults.user} media -"
    "d /data/Downloads/books 775 ${config.my.defaults.user} media -"
  ];
}
