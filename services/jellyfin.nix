{ config, pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "jellyfin";
    group = "jellyfin";
  };

  # Add jellyfin user to required groups for hardware acceleration AND media access
  users.users.jellyfin.extraGroups = [ "video" "render" "media" ];

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

  # REMOVED: Media directories (now handled centrally in configuration.nix)
  # This prevents duplicate tmpfiles rules
}