{ config, pkgs, lib, ... }:

{
  services.microbin = {
    enable = true;
    settings = {
      MICROBIN_BIND = "127.0.0.1";
      MICROBIN_PORT = "8083";
      MICROBIN_PUBLIC_PATH = "http://192.168.1.165:80/microbin";
      MICROBIN_EDITABLE = true;
      MICROBIN_HIGHLIGHTSYNTAX = true;
      MICROBIN_TITLE = "Homeserver Pastebin";
      MICROBIN_ADMIN_USERNAME = "admin";
      MICROBIN_ADMIN_PASSWORD = config.sops.secrets.microbin_admin_password.path;
    };
  };
  
  # SOPS secret for Microbin
  sops.secrets.microbin_admin_password = {};
  
  # Open firewall for Microbin
  networking.firewall.allowedTCPPorts = [ 8083 ];
}
