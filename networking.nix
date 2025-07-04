{ config, pkgs, lib, ... }:

{
  # Hostname
  networking.hostName = "homeserver";

  # Use NetworkManager
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkForce false;

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22    # SSH
      80    # HTTP (Caddy)
      443   # HTTPS (Caddy)
      8080  # Keycloak
      8081  # Nextcloud
      8082  # Homepage
      8083  # Microbin or Miniflux
      8084  # Miniflux or other
      8085  # Audiobookshelf
      8096  # Jellyfin
      8888  # Paperless
      5232  # Radicale
      8123  # Home Assistant
      51413 # Deluge
    ];
  };
}
