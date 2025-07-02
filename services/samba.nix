{ config, pkgs, ... }:

{
  services.samba = {
    enable = true;
    openFirewall = true;
    
    settings = {
      global = {
        workgroup = "WORKGROUP";
        server string = "NixOS Samba Server";
        netbios name = "homeserver";
        security = "user";
        hosts allow = "192.168.1. 127.0.0.1 localhost";
        hosts deny = "0.0.0.0/0";
        guest account = "nobody";
        map to guest = "bad user";
      };
      
      media = {
        path = "/home/zeev/media";
        browseable = "yes";
        writeable = "yes";
        "guest ok" = "no";
        "valid users" = "zeev";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      
      downloads = {
        path = "/home/zeev/downloads";
        browseable = "yes";
        writeable = "yes";
        "guest ok" = "no";
        "valid users" = "zeev";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  # Samba users need to be added manually after installation with:
  # sudo smbpasswd -a zeev
}