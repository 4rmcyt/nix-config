{ config, pkgs, ... }:

{
  sops.secrets.microbin_admin_password = { };

  services.microbin = {
    enable = true;
    settings = {
      MICROBIN_BIND = "127.0.0.1";
      MICROBIN_PORT = "8087";
      MICROBIN_PUBLIC_PATH = "https://paste.labhome.work";
      MICROBIN_EDITABLE = "true";
      MICROBIN_HIDE_FOOTER = "true";
      MICROBIN_HIDE_HEADER = "true";
      MICROBIN_HIDE_LOGO = "true";
      MICROBIN_NO_LISTING = "true";
      MICROBIN_HIGHLIGHTSYNTAX = "true";
      MICROBIN_TITLE = "LabHome Paste";
    };
  };

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8087 ];
}