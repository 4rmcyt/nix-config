{ config, pkgs, ... }:

{
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0"; # TODO: Fix it after reverse proxy will be ready
    port = 8085;
    libraries = [
      {
        name = "Audiobooks";
        path = "/home/zeev/media/audiobooks";
        type = "audiobooks";
      }
    ];
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
