{ config, pkgs, lib, ... }:

{
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 8085;
    # Don't set dataDir here - let NixOS use its default
  };

  # Add the audiobookshelf user to media group
  users.users.audiobookshelf.extraGroups = [ "media" ];

  # Create directories and ensure proper permissions
  systemd.tmpfiles.rules = [
    # Media directories - keep them owned by zeev but accessible by media group
    "d /home/zeev/media/audiobooks 0775 zeev media -"
    "d /home/zeev/media/podcasts 0775 zeev media -"
  ];

  # Fix the systemd service configuration to avoid the double path issue
  systemd.services.audiobookshelf = {
    serviceConfig = {
      # Override the working directory properly
      WorkingDirectory = lib.mkForce "/var/lib/audiobookshelf";
      # Make sure the service can access media files
      SupplementaryGroups = [ "media" ];
    };
    # Ensure the service starts correctly
    preStart = lib.mkBefore ''
      # Ensure the working directory exists and has correct permissions
      mkdir -p /var/lib/audiobookshelf
      chown audiobookshelf:audiobookshelf /var/lib/audiobookshelf
      chmod 755 /var/lib/audiobookshelf

      # Remove any broken symlinks
      find /var/lib/audiobookshelf -type l ! -exec test -e {} \; -delete 2>/dev/null || true
    '';
  };

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8085 ];
}