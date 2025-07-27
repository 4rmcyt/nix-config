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
    # Optional: Configure user and group for the service
    user = "calibre-web-user";
    group = "calibre-web-group";
    # Optional: Enable uploads from the web interface
    enableUploads = true;
    # Optional: Configure other features as needed
    # options = {
    #   # ... specific Calibre-Web configuration options ...
    # };
  };
}
