{
  config,
  pkgs,
  lib,
  ...
}:
{

  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets.kavita_token_key_file.path;
    settings = {
      UI = {
        Theme = "dark";
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
