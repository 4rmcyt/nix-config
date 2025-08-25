_:
{
  users.users.samba = {
    isSystemUser = true;
    group = "samba";
    extraGroups = [
      "users"
      "media"
    ];
  };

  users.groups.samba = { };

  networking.firewall.allowedTCPPorts = [
    139 # Samba NetBIOS Session Service
    445 # Samba SMB over TCP
  ];

  services.samba = {
    enable = true;
    openFirewall = true;

    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "NixOS Samba Server"; # Fixed: quoted attribute name
        "netbios name" = "homeserver"; # Fixed: quoted attribute name
        security = "user";
        "map to guest" = "bad user";
      };

      media = {
        path = "/data/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "zeev";
        "force group" = "users";
      };

      downloads = {
        path = "/data/Downloads";
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
}
