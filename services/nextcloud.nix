# /etc/nixos/services/nextcloud.nix
{ config, pkgs,... }:

{
  sops.secrets.nextcloud_admin_password = { };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28; # Update this for major upgrades
    hostName = "nextcloud.example.com"; # Replace with your domain
    listenAddress = "127.0.0.1";
    port = 8081; # Matches the port in cloudflared.nix
    https = false;

    database.createLocally = true;
    configureRedis = true;

    config = {
      adminuser = "zeev";
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
      dbtype = "pgsql";
    };

    maxUploadSize = "10G";
    autoUpdateApps.enable = true;
  };
}