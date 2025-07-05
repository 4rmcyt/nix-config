{ config, pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "jellyfin";
    group = "jellyfin";
    mediaDirectories = [
      { name = "Movies"; path = "/home/zeev/media/movies"; }
      { name = "TV"; path = "/home/zeev/media/tv"; }
      { name = "Series"; path = "/home/zeev/media/series"; }
      { name = "Music"; path = "/home/zeev/media/music"; }
      { name = "Other"; path = "/home/zeev/media/other"; }
    ];
  };

  # Add jellyfin user to video group for hardware acceleration
  users.users.jellyfin.extraGroups = [ "video" "render" ];

  # Enable hardware acceleration for Intel graphics (server compatible)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # Server compatible
      intel-vaapi-driver  # Server compatible
      vaapiVdpau         # Server compatible
      libvdpau-va-gl     # Server compatible
    ];
  };

  # Open firewall ports
  networking.firewall.allowedTCPPorts = [ 8096 8920 ];
  networking.firewall.allowedUDPPorts = [ 1900 7359 ];
}