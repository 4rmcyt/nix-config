{ config, pkgs, ... }:

{
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 8085;
    dataDir = "/home/zeev/media/audiobooks"
  };

  # Create media directories
  systemd.tmpfiles.rules = [
    "d /var/lib/audiobookshelf 0755 audiobookshelf audiobookshelf -"
    "d /home/zeev/media/audiobooks 0770 zeev media -"
    "d /home/zeev/media/podcasts 0770 zeev media -"
  ];
  

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8085 ];
}
