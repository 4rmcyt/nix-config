{ config, pkgs, ... }:

{ 
  environment.systemPackages = [ pkgs.samba ]; 
  services.samba = {
    enable = true;
    openFirewall = true;
    
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "NixOS Samba Server";  # Fixed: quoted attribute name
        "netbios name" = "homeserver";           # Fixed: quoted attribute name
        security = "user";
        "map to guest" = "bad user";
      };
      
      media = {
        path = "/home/zeev/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "zeev";
        "force group" = "users";
      };
      
      downloads = {
        path = "/home/zeev/downloads";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "zeev";
        "force group" = "users";
      };
    };
  };
  users.users.samba = {
    isSystemUser = true;
    group = "samba";
    extraGroups = [ "users" "media" ];
  };
  users.groups.samba = {};
}