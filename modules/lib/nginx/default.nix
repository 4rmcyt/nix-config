{ config, lib, ... }:

let
  mkReverseProxy = {
    subdomain,
    port,
    enableWebsockets ? true,
    extraLocations ? {},
    extraVhostConfig ? {},
  }: {
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."${subdomain}.${config.my.defaults.domain}" = lib.mkMerge [
        {
          forceSSL = true;
          sslCertificate = config.my.security.ssl.certPath;
          sslCertificateKey = config.my.security.ssl.keyPath;

          locations."/" = {
            proxyPass = "http://localhost:${toString port}";
            proxyWebsockets = enableWebsockets;
          };
        }
        extraVhostConfig
        {
          locations = extraLocations;
        }
      ];
    };
  };
in
{
  lib = lib // {
    mkReverseProxy = mkReverseProxy;
  };
}
