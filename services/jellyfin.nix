
{ config, pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "jellyfin";
    group = "jellyfin";
  };

  # Add jellyfin user to video and render groups for hardware acceleration
  users.users.jellyfin.extraGroups = [ "video" "render" ];

  # Enable hardware graphics acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Open necessary ports for Jellyfin
  networking.firewall.allowedTCPPorts = [ 8096 8920 ];
  networking.firewall.allowedUDPPorts = [ 1900 7359 ];

  # Ensure media directories exist and have proper permissions
  systemd.tmpfiles.rules = [
    "d /home/zeev/media/movies 0770 zeev media -"
    "d /home/zeev/media/tv 0770 zeev media -"
    "d /home/zeev/media/series 0770 zeev media -"
    "d /home/zeev/media/music 0770 zeev media -"
    "d /home/zeev/media/other 0770 zeev media -"
  ];
}