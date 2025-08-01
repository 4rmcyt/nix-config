{
  pkgs,
  lib,
  config,
  ...
}:
{

  services.linkwarden = {
    enable = true;
    package = mypkgs.linkwarden;
    settingsFile = config.sops.secrets.linkwarden_settings.path;
    settings = {
      VIRTUAL_PORT = "12522";
      VIRTUAL_HOST = "link.example.com";
    };
  };

  service.nginx.virtualHosts."link.example.com" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyPass = "http://localhost:12522";
      proxyWebsockets = true;
      proxyHeaders = {
        "X-Forwarded-For" = "$proxy_add_x_forwarded_for";
        "X-Forwarded-Proto" = "https";
      };
    };
  };
  
  networking.firewall.allowedTCPPorts = [
    12522 # Linkwarden
  ];
  
  users.users.linkwarden = {
    isSystemUser = true;
    group = "linkwarden";
    extraGroups = [ "users" ];
  };
  users.groups.linkwarden = { };
}
