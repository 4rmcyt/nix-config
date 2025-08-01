{
  config,
  pkgs,
  lib,
  ...
}:

{
  environment.systemPackages = [
    pkgs.calibre-web
  ];

  nixpkgs.overlays = [
    (final: prev: {
      python3Packages = prev.python3Packages.override {
        overrides = self: super: {
          unidecode = super.unidecode.overrideAttrs (old: {
            pname = "Unidecode";
            version = "1.3.8";
            src = prev.fetchPypi {
              pname = "Unidecode";
              version = "1.3.8";
              hash = "sha256-z9s0nUbtOHPs5Fhrlqp1JYcm4vqOwh1vAKWR2YgGwvQ=";
            };
          });
        };
      };
    })
  ];

  services.calibre-web = {
    enable = true;
    listen = {
      port = 8083;
      ip = "127.0.0.1";
    };
    options = {
      enableBookConversion = true;
      calibreLibrary = "/data/media/books";
    };
  };
  services.nginx.virtualHosts."calibre-web.example.com" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyPass = "http://localhost:8083";
      proxyWebsockets = true;
      proxyHeaders = {
        "X-Forwarded-For" = "$proxy_add_x_forwarded_for";
        "X-Forwarded-Proto" = "https";
      };
    };
  };
  networking.firewall.allowedTCPPorts = [
    8083 # Calibre-Web
  ];
  users.users.calibre-web = {
    isSystemUser = true;
    extraGroups = [ "users" "calibre-web" "media" ];
  };
  users.groups.calibre-web = {};
}
