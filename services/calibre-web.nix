{
  config,
  pkgs,
  lib,
  ...
}:

{
  users.calibre-web = {
    isSystemUser = true;
    extraGroups = [ "users" "calibre-web" "media" ];
  };
  users.groups.calibre-web = {};

  nixpkgs.overlays = [
    (final: prev: {
      python3Packages = prev.python3Packages.override {
        overrides = self: super: {
          unidecode = super.unidecode.overrideAttrs (old: {
            pname = "Unidecode";
            version = "1.3.8";
            src = prev.fetchPypi {
              pname = "Unidecode";
              version = "1.3.8";
              hash = "sha256-z9s0nUbtOHPs5Fhrlqp1JYcm4vqOwh1vAKWR2YgGwvQ=";
            };
          });
        };
      };
    })
  ];

  services.calibre-web = {
    enable = true;
    listen = {
      port = 8083;
      ip = "127.0.0.1";
    };
    options = {
      enableBookConversion = true;
      calibreLibrary = "/data/media/books";
    };
  };
}
