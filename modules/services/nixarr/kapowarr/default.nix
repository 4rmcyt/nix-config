{config, ...}: let
  port = toString config.my.network.ports.kapowarr;
in {
  virtualisation.oci-containers.containers.kapowarr = {
    autoStart = true;
    image = "docker.io/mrcas/kapowarr:latest";
    # Published ports are DNAT'd past the NixOS firewall: bind loopback (reverse proxy) + LAN IP only.
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
      "--env=PUID=1000"
      "--env=PGID=${toString config.users.groups.media.gid}"
      "--env=TZ=${config.my.defaults.timezone}"
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
    volumes = [
      "/data/media/.state/nixarr/kapowarr:/app/db:idmap"
      "/data/Downloads/kapowarr:/app/temp_downloads:idmap"
      "/data/media/manga:/manga:idmap"
      "/data/media/comics:/comics:idmap"
    ];
  };

  systemd.services.podman-kapowarr = {
    after = ["data.mount"];
    requires = ["data.mount"];
  };

  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/kapowarr 775 ${config.my.defaults.user} media -"
    "d /data/Downloads/kapowarr 775 ${config.my.defaults.user} media -"
  ];
}
