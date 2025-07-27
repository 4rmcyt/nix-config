{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.calibre-web = {
    enable = true;
    user = "admin";
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
