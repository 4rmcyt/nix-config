{ config, pkgs, lib, ... }:

{
  services.microbin = {
    enable = true;
    listenAddr = "0.0.0.0";
    port = 8083;
    environmentFile = config.sops.secrets.microbin_secrets.path;

    settings = {
      admin_username = "admin";
      private = true;
      no_listing = true;
    };
  };
}
