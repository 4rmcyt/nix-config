{
  config,
  lib,
  ...
}: {
  services.lazylibrarian = {
    enable = true;
    port = config.my.network.ports.lazylibrarian;
    dataDir = "/data/media/.state/nixarr/lazylibrarian";
    openFirewall = false;
    settings = {
      general = {
        logdir = "/data/media/.state/nixarr/lazylibrarian/logs";
        destination = "/data/media/books";
        download_dir = "/data/Downloads/books";
      };
    };
  };

  systemd.services.lazylibrarian = {
    after = ["data.mount"];
    requires = ["data.mount"];
    serviceConfig = {
      UMask = lib.mkForce "0002";
      BindPaths = [
        "/data/Downloads"
        "/data/media"
        "/data/media/.state"
      ];
      # upstream sets ProtectSystem=strict which blocks /data writes
      ProtectSystem = lib.mkForce "false";
      ReadWritePaths = lib.mkForce [];
    };
  };

  users.users.lazylibrarian.extraGroups = [
    "users"
    "media"
  ];

  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/lazylibrarian 775 lazylibrarian lazylibrarian -"
    "d /data/media/.state/nixarr/lazylibrarian/logs 775 lazylibrarian lazylibrarian -"
    "d /data/Downloads/books 775 ${config.my.defaults.user} media -"
  ];

  networking.firewall.allowedTCPPorts = [config.my.network.ports.lazylibrarian];
}
