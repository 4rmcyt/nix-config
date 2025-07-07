{ config, pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    user = "jellyfin";
    group = "jellyfin";
    openFirewall = true;
  };

  users.users.jellyfin = {
    extraGroups = [ "render" "video" "media" ];
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      libvdpau-va-gl
    ];
  };

  systemd.services.jellyfin = {
    serviceConfig.SupplementaryGroups = [ "render" "video" ];
  };
}
