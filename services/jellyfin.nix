{ config, pkgs, ... }:

{
  # Enable Intel GPU support for hardware acceleration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    extraPackages = with pkgs; [
      intel-media-driver  # For newer Intel GPUs (Broadwell+)
      vaapiIntel          # For older Intel GPUs
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime # OpenCL support
    ];
  };

  # Enable hardware video acceleration
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    # Jellyfin runs on port 8096 by default
  };

  # Add jellyfin user to video and render groups for GPU access
  users.users.jellyfin.extraGroups = [ "video" "render" ];

  # Create media directories
  systemd.tmpfiles.rules = [
    "d /home/zeev/media 0755 zeev users -"
    "d /home/zeev/media/movies 0755 zeev users -"
    "d /home/zeev/media/tv 0755 zeev users -"
    "d /home/zeev/media/music 0755 zeev users -"
  ];

  # Allow jellyfin to access media files
  systemd.services.jellyfin.serviceConfig = {
    BindReadOnlyPaths = [
      "/home/zeev/media:/media"
    ];
  };
}