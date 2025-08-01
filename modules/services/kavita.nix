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

  users.users.kavita = {
    isSystemUser = true;
    group = "kavita";
    extraGroups = [ "users" "media" "kavita" ];
  };
  users.groups.kavita = { };

  services.nginx.virtualHosts."kavita.example.com" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyPass = "http://localhost:5000";
      proxyWebsockets = true;
      proxyHeaders = {
        "X-Forwarded-For" = "$proxy_add_x_forwarded_for";
        "X-Forwarded-Proto" = "https";
      };
    };
  };
  
  networking.firewall.allowedTCPPorts = [
    5000 # Kavita
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/kavita 0755 kavita kavita -"
    "d /var/lib/kavita/libraries 0755 kavita kavita -"
    "d /var/lib/kavita/config 0755 kavita kavita -"
    "d /var/lib/kavita/logs 0755 kavita kavita -"
  ];
}
