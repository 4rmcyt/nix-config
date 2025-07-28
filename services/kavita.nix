{
  config,
  pkgs,
  lib,
  ...
}:
{
  users.kavita = {
    isSystemUser = true;
    group = "kavita";
    extraGroups = [ "users" "media" ];
  };
  user.groups.kavita = { };
  
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
}
