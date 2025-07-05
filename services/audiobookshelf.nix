{ config, pkgs, ... }:

{
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 8085;
    dataDir = "/var/lib/audiobookshelf";
  };

  # Ensure audiobookshelf user exists and has proper permissions
  users.users.audiobookshelf = {
    isSystemUser = true;
    group = "audiobookshelf";
    home = "/var/lib/audiobookshelf";
    createHome = true;
    extraGroups = [ "media" ];
  };

  users.groups.audiobookshelf = {};

  # Create all necessary directories with proper permissions
  systemd.tmpfiles.rules = [
    # Service data directory
    "d /var/lib/audiobookshelf 0755 audiobookshelf audiobookshelf -"
    "d /var/lib/audiobookshelf/config 0755 audiobookshelf audiobookshelf -"
    "d /var/lib/audiobookshelf/metadata 0755 audiobookshelf audiobookshelf -"

    # Media directories - accessible by audiobookshelf user
    "d /home/zeev/media/audiobooks 0770 zeev media -"
    "d /home/zeev/media/podcasts 0770 zeev media -"

    # Create symlinks for easier access
    "L+ /var/lib/audiobookshelf/audiobooks - - - - /home/zeev/media/audiobooks"
    "L+ /var/lib/audiobookshelf/podcasts - - - - /home/zeev/media/podcasts"
  ];

  # Override the systemd service to ensure proper working directory
  systemd.services.audiobookshelf = {
    serviceConfig = {
      WorkingDirectory = "/var/lib/audiobookshelf";
      # Ensure the service has access to media files
      SupplementaryGroups = [ "media" ];
    };
  };

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8085 ];
}