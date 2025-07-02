{ config, pkgs, ... }:

{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "LabHome NAS";
        "netbios name" = "homeserver";
        "security" = "user";
        "hosts allow" = "192.168.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      
      "media" = {
        "path" = "/home/zeev/media";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = "zeev";
      };
      
      "downloads" = {
        "path" = "/home/zeev/downloads";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = "zeev";
      };
    };
  };

  # Set Samba password for user (run manually: sudo smbpasswd -a zeev)
  users.users.zeev.extraGroups = [ "samba" ];
}