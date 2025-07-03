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
      80    # HTTP
      443   # HTTPS
      8082  # Homepage (current port)
      8096  # Jellyfin
    ];
  };
}
