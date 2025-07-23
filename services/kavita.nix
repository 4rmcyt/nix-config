{ config, pkgs, lib, ... }: 
{


  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets.kavita_token_key_file.path;
    settings = {
      Database = {
        ConnectionString = "Server=your_server;Database=kavita;User Id=your_user;Password=your_password;";
      };
      UI = {
        Theme = "dark";
      };
      Libraries = [
        {
          Path = "/mnt/data/comics";
        }
      ];
    };
}; 
}
