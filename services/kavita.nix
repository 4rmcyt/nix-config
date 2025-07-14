{ config, pkgs, lib, ... }: 
{
  users.users.kavita = {
    isSystemUser = true;
    group = "kavita";
    home = lib.mkForce "/data/kavita";
    extraGroups = [ "media" ];
  };

  users.groups.kavita = {};

  services.kavita = {
    enable = true;
    user = "kavita";
    dataDir = "/data/kavita";

  };  
}
