{ config, pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "jellyfin";
    group = "jellyfin";

    settings = {
      movies = {
        name = "Movies";
        content_type = "movies";
        paths = [ "/home/zeev/media/movies" ];
        enable = true;
      };
      tv = {
        name = "TV";
        content_type = "shows";
        paths = [ "/home/zeev/media/tv" "/home/zeev/media/series" ];
        enable = true;
      };
      music = {
        name = "Music";
        content_type = "music";
        paths = [ "/home/zeev/media/music" ];
        enable = true;
      };
      other = {
        name = "Other";
        content_type = "mixed";
        paths = [ "/home/zeev/media/other" ];
        enable = true;
      };
    };
  };

  users.users.jellyfin.extraGroups = [ "video" "render" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  networking.firewall.allowedTCPPorts = [ 8096 8920 ];
  networking.firewall.allowedUDPPorts = [ 1900 7359 ];
}