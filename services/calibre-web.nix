{
  config,
  pkgs,
  lib,
  ...
}:
{
   services.calibre-web.package = pkgs.calibre-web.overrideAttrs ({ propagatedBuildInputs ? [ ], ... }: {
    propagatedBuildInputs = propagatedBuildInputs ++ [
      pkgs.python313Packages.unidecode
    ];
  });

  services.calibre-web = {
    enable = true;
    listen = {
      port = 8083;
      ip = "127.0.0.1";
    };
    options = {
      enableBookConversion = true;
      enableKepubify = true;
      calibreLibrary = "/data/media/books";
    };
  };
}
