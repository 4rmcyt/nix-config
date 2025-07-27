{
  config,
  pkgs,
  lib,
  ...
}:
{

  services.kavita = {
    enable = true;
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
