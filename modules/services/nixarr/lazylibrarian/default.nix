{config, ...}: {
  virtualisation.oci-containers.containers.lazylibrarian = {
    autoStart = true;
    image = "lscr.io/linuxserver/lazylibrarian:latest";
    extraOptions = [
      "--network=host"
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
      "/data/media/.state/nixarr/lazylibrarian:/config"
      "/data/media/books:/books"
      "/data/Downloads/books:/downloads"
      "/data/media/audiobooks:/audiobooks"
      "/data/Downloads/audiobooks:/downloads-audiobooks"
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
