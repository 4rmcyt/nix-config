{ config, pkgs, ... }:

{
  services.audiobookshelf = {
    enable = true;
    host = "127.0.0.1";
    port = 8085;
    dataDir = "/var/lib/audiobookshelf";
    serviceConfig.WorkingDirectory = "/var/lib/audiobookshelf";
  };

  # Create media directories
  systemd.tmpfiles.rules = [
    "d /var/lib/audiobookshelf 0755 audiobookshelf audiobookshelf -"
    "d /home/zeev/audiobooks 0755 zeev users -"
    "d /home/zeev/podcasts 0755 zeev users -"
  ];
  

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8085 ];
}
