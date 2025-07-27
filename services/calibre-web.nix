{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.calibre-web = {
    enable = true;
    libraryPath = "/data/media/books";
    listen = {
      port = 8083;
      ip = "0.0.0.0"; # Listen on all interfaces
    };
    enableUploads = true;

  };
}
