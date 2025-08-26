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
    virtualHosts."calibre-web.labhome.work" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
      locations."/" = {
        proxyPass = "http://localhost:8083";
        proxyWebsockets = true;
      };
    };
  };
  environment.systemPackages = [ pkgs.calibre-web ];

  

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
