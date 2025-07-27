{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.calibre-web = {
    enable = true;
    dataDir = "/data/media/books";
    listen = {
      port = 8083;
      ip = "127.0.0.1";
    };
    options = {
      enableUserManagement = true;
      enableBookConversion = true;
    };
  };
}
