{
  config,
  pkgs,
  lib,
  ...
}:
{ 
  environment.systemPackages = [
    pkgs.kavita
  ];

  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets.kavita_token_key_file.path;
    settings = {
      UI = {
        Theme = "dracula";
      };
      Libraries = [
        {
          Path = "/data/media/comics";
        }
        {
          Path = "/data/media/manga";
        }
      ];
    };
  };
  
  users.kavita = {
    isSystemUser = true;
    group = "kavita";
    extraGroups = [ "users" "media" ];
  };
  user.groups.kavita = { };

  systemd.tmpfiles.rules = [
    "d /var/lib/kavita 0755 kavita kavita -"
    "d /var/lib/kavita/libraries 0755 kavita kavita -"
    "d /var/lib/kavita/config 0755 kavita kavita -"
    "d /var/lib/kavita/logs 0755 kavita kavita -"
  ];
}
