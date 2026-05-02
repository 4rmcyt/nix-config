{
  config,
  lib,
  pkgs,
  ...
}: let
  dataDir = "/data/media/.state/nixarr/lazylibrarian";
  writableConfig = "${dataDir}/config.ini";
  # The upstream module generates a read-only config.ini in the nix store.
  # We capture it here so we can copy it to a writable path on first start.
  generatedConfig = (pkgs.formats.ini {}).generate "lazylibrarian-config.ini" (
    lib.recursiveUpdate {
      general = {
        http_port = config.my.network.ports.lazylibrarian;
        install_type = "source";
        auto_update = false;
      };
    } {
      general = {
        logdir = "${dataDir}/logs";
        destination = "/data/media/books";
        download_dir = "/data/Downloads/books";
      };
    }
  );
in {
  services.lazylibrarian = {
    enable = true;
    port = config.my.network.ports.lazylibrarian;
    dataDir = dataDir;
    openFirewall = false;
    settings = {
      general = {
        logdir = "${dataDir}/logs";
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
      ReadWritePaths = lib.mkForce [dataDir];
      # Override upstream ExecStart to use writable config path
      ExecStart = lib.mkOverride 0 "${config.services.lazylibrarian.package}/bin/lazylibrarian --datadir=${dataDir} --config=${writableConfig}";
    };
    preStart = ''
      if [ ! -f ${writableConfig} ]; then
        cp ${generatedConfig} ${writableConfig}
        chmod 600 ${writableConfig}
      fi
    '';
  };

  users.users.lazylibrarian.extraGroups = [
    "users"
    "media"
  ];

  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/lazylibrarian 775 lazylibrarian lazylibrarian -"
    "d /data/media/.state/nixarr/lazylibrarian/logs 775 lazylibrarian lazylibrarian -"
    "d /data/media/.state/nixarr/lazylibrarian/cache 775 lazylibrarian lazylibrarian -"
    "d /data/Downloads/books 775 ${config.my.defaults.user} media -"
  ];

  networking.firewall.allowedTCPPorts = [config.my.network.ports.lazylibrarian];
}
