{ config, pkgs, lib, ... }:

{
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 8085;
    dataDir = "/var/lib/audiobookshelf";
  };

  # Don't manually define the audiobookshelf user - the service creates it automatically
  # Just add it to the media group after the service creates it
  users.users.audiobookshelf.extraGroups = [ "media" ];

  # Create all necessary directories with proper permissions
  systemd.tmpfiles.rules = [
    # Media directories - accessible by audiobookshelf user
    "d /home/zeev/media/audiobooks 0770 zeev media -"
    "d /home/zeev/media/podcasts 0770 zeev media -"

    # Create symlinks for easier access (after ensuring the dataDir exists)
    "L+ /var/lib/audiobookshelf/audiobooks - - - - /home/zeev/media/audiobooks"
    "L+ /var/lib/audiobookshelf/podcasts - - - - /home/zeev/media/podcasts"
  ];

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8085 ];
}