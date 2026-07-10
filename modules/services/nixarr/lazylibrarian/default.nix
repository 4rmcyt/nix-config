{config, ...}: {
  virtualisation.oci-containers.containers.lazylibrarian = {
    autoStart = true;
    image = "lscr.io/linuxserver/lazylibrarian:latest";
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
    ];
    environment = {
      PUID = "1000";
      PGID = toString config.users.groups.media.gid;
      TZ = config.my.defaults.timezone;
      DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg";
    };
    volumes = [
      "/data/media/.state/nixarr/lazylibrarian:/config"
      "/data/media/books:/books"
      "/data/Downloads/books:/downloads"
    ];
  };

  systemd.services.podman-lazylibrarian = {
    after = ["data.mount"];
    requires = ["data.mount"];
  };

  networking.firewall.allowedTCPPorts = [config.my.network.ports.lazylibrarian];

  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/lazylibrarian 775 ${config.my.defaults.user} media -"
    "d /data/Downloads/books 775 ${config.my.defaults.user} media -"
  ];
}
