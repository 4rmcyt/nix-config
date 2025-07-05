
{ config, pkgs, lib, ... }:

{
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 8085;
  };

  # Add the audiobookshelf user to media group
  users.users.audiobookshelf.extraGroups = [ "media" ];

  # Create directories and ensure proper permissions
  systemd.tmpfiles.rules = [
    # Media directories - make them accessible by media group
    "d /home/zeev/media/audiobooks 0775 zeev media -"
    "d /home/zeev/media/podcasts 0775 zeev media -"
  ];

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8085 ];
}