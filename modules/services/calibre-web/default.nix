{ pkgs, ... }:
{
  users.users.calibre-web = {
    isSystemUser = true;
    extraGroups = [
      "users"
      "calibre-web"
      "media"
    ];
  };
  users.groups.calibre-web = { };

  networking.firewall.allowedTCPPorts = [
    8083 # Calibre-Web
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."calibre-web.example.com" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/example.com/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/example.com/key.pem";
      locations."/" = {
        proxyPass = "http://localhost:8083";
        proxyWebsockets = true;
      };
    };
  };
  environment.systemPackages = [ pkgs.calibre-web ];

  nixpkgs.overlays = [
    (final: prev: {
      python3 = prev.python3.override {
        packageOverrides = self: super: {
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
}
