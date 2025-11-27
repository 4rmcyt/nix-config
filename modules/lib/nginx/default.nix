{
  config,
  lib,
  ...
}: let
  # Helper function to create a reverse proxy nginx virtualHost
  # Note: Base nginx configuration (enable, recommended settings) is managed in
  # modules/networking/nginx/default.nix - this helper only defines virtualHosts
  mkReverseProxy = {
    subdomain,
    port,
    enableWebsockets ? true,
    extraLocations ? {},
    extraVhostConfig ? {},
  }: {
    services.nginx.virtualHosts."${subdomain}.${config.my.defaults.domain}" = lib.mkMerge [
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
in {
  lib =
    lib
    // {
      inherit mkReverseProxy;
    };
}
