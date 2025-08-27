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
      groups.podman = { };
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
}
