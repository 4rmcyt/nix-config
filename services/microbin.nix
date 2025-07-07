
{ config, pkgs, lib, ... }:

{
  services.microbin = {
    enable = true;
    settings = {
      MICROBIN_BIND = "127.0.0.1";
      MICROBIN_PORT = "8083";
      MICROBIN_PUBLIC_PATH = "https://paste.labhome.work";
      MICROBIN_EDITABLE = true;
      MICROBIN_HIGHLIGHTSYNTAX = true;
      MICROBIN_TITLE = "Homeserver Pastebin";
      MICROBIN_ADMIN_USERNAME = "admin";
      MICROBIN_ADMIN_PASSWORD = config.sops.secrets.microbin_admin_password.path;
    };
  };
  
  # SOPS secret for Microbin
  sops.secrets.microbin_admin_password = {};
  
  # REMOVED: Firewall port (now handled centrally in networking.nix)
}