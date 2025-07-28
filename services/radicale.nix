{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.radicale ];
  services.radicale = {
    enable = true;
    settings = {
      server = {
        hosts = [ "127.0.0.1:5232" ];
      };

      auth = {
        type = "htpasswd";
        htpasswd_filename = config.sops.secrets.radicale_users.path;
        htpasswd_encryption = "bcrypt";
      };

      storage = {
        filesystem_folder = "/var/lib/radicale/collections";
      };

      web = {};

      logging = {
        level = "info";
      };
    };
  };


  systemd.tmpfiles.rules = [
    "d /var/lib/radicale/collections 0750 radicale radicale -"
  ];
  users.radicale = {
    isSystemUser = true;
    group = "radicale";
    extraGroups = [ "users" ];
  };
  users.groups.radicale = {};
}
