{
  config,
  lib,
  pkgs,
  ...
}:
{
  users.users.calibre-web = {
    isSystemUser = true;
    group = "calibre-web";
    extraGroups = [
      "users"
      "media"
    ];
  };

  users.groups.calibre-web = { };

  services.calibre-web = {
    enable = true;
    listen = {
      ip = "127.0.0.1";
      port = 8084;
    };
    options = {
      calibreLibrary = "/data/media/books";
      enableBookUploading = true;
      enableBookConversion = true;
    };
  };

  systemd.services.calibre-web = {
    serviceConfig = {
      UMask = lib.mkDefault "0002";
      User = lib.mkForce "calibre-web";
      Group = lib.mkForce "calibre-web";
      BindPaths = [
        "/data/media/books"
        "/data/media/manga"
        "/data/media/comics"
      ];
    };
  };

}
