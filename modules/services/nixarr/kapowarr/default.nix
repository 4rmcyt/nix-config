{config, ...}: {
  virtualisation.oci-containers.containers.kapowarr = {
    autoStart = true;
    image = "docker.io/mrcas/kapowarr:latest";
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--env=PUID=1000"
      "--env=PGID=${toString config.users.groups.media.gid}"
      "--env=TZ=${config.my.defaults.timezone}"
    ];
    volumes = [
      "/data/media/.state/nixarr/kapowarr:/app/db"
      "/data/Downloads/kapowarr:/app/temp_downloads"
      "/data/media/manga:/manga"
      "/data/media/comics:/comics"
    ];
  };

  systemd.services.podman-kapowarr = {
    after = ["data.mount"];
    requires = ["data.mount"];
  };

  networking.firewall.allowedTCPPorts = [
    config.my.network.ports.kapowarr
  ];

  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/kapowarr 775 ${config.my.defaults.user} media -"
    "d /data/Downloads/kapowarr 775 ${config.my.defaults.user} media -"
  ];
}
