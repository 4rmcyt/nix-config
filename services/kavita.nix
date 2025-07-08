
{ config, pkgs, ... }:

{
  users.users.kavita = {
    isSystemUser = true;
    group = "kavita";
    home = "/var/lib/kavita";
    extraGroups = [ "media" ];
  };

  users.groups.kavita = {};
  services.kavita = {
    enable = true;
    user = "kavita";
    dataDir = "/home/zeev/media/library";
  };
}