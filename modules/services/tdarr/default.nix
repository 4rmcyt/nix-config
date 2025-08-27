{ pkgs, ... }:

{
  user = {
    users.tdarr = {
      isSystemUser = true;
      group = "media";
      extraGroups = [
        "users"
        "media"
      ];
      groups.tdarr = { };
    };
  };

  services.tdarr = {
    enable = true;
    tdarr.enable = true;
    user = "tdarr";
    group = "media";
    mediaDir = "/data/media";
    cacheDir = "/data/media/transcode-cache";
  };

  systemd.tmpfiles.rules = [
    "d /data/media/transcode-cache 775 tdarr media -"
    "d /var/lib/tdarr/logs 775 tdarr tdarr -"
    "d /var/lib/tdarr/configs 775 tdarr tdarr -"
  ];
}
