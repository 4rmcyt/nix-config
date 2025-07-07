{ config, pkgs, lib, ... }:

{
  sops.secrets.miniflux_admin_password = { };

  # Miniflux RSS reader - Fix: Use correct port 8086
  services.miniflux = {
    enable = true;
    config = {
      LISTEN_ADDR = "127.0.0.1:8086";  # Changed from 8084 to 8086
      services.miniflux = {
    enable = true;
    adminUser = "admin";
    adminPasswordFile = config.sops.secrets.miniflux_admin_password.path;
    };
    adminCredentialsFile = config.sops.secrets.miniflux_admin_password.path;
  };

}