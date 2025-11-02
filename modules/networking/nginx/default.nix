{lib}: rec {
  # Helper to create a service configuration with both nginx and cloudflared tunnel
  mkProxyService = {
    # Service identification
    subdomain,
    port,
    # Domain configuration
    domain ? "example.com",
    # Nginx configuration
    enableNginx ? true,
    enableSSL ? true,
    certPath ? "/var/lib/acme/${domain}/fullchain.pem",
    keyPath ? "/var/lib/acme/${domain}/key.pem",
    websockets ? false,
    extraNginxLocations ? {},
    extraNginxConfig ? {},
    # Cloudflared configuration
    enableCloudflared ? false,
    cloudflaredTarget ? "http://localhost:${toString port}",
  }: let
    hostname = "${subdomain}.${domain}";
  in {
    # Nginx virtual host configuration
    nginx = lib.optionalAttrs enableNginx {
      virtualHosts.${hostname} =
        {
          forceSSL = enableSSL;
          sslCertificate = certPath;
          sslCertificateKey = keyPath;
          locations."/" =
            {
              proxyPass = "http://localhost:${toString port}";
            }
            // lib.optionalAttrs websockets {
              proxyWebsockets = true;
            };
        }
        // extraNginxLocations
        // extraNginxConfig;
    };

    # Cloudflared tunnel ingress entry
    cloudflared = lib.optionalAttrs enableCloudflared {
      ingress.${hostname} = cloudflaredTarget;
    };
  };

  # Creates a standard nginx virtual host configuration for reverse proxy with SSL
  mkNginxVirtualHost = {
    subdomain,
    domain ? "example.com",
    port,
    enableSSL ? true,
    certPath ? "/var/lib/acme/${domain}/fullchain.pem",
    keyPath ? "/var/lib/acme/${domain}/key.pem",
    websockets ? false,
    extraLocations ? {},
    extraConfig ? {},
  }: let
    hostname = "${subdomain}.${domain}";
  in
    lib.nameValuePair hostname ({
        forceSSL = enableSSL;
        sslCertificate = certPath;
        sslCertificateKey = keyPath;
        locations."/" =
          {
            proxyPass = "http://localhost:${toString port}";
          }
          // lib.optionalAttrs websockets {
            proxyWebsockets = true;
          };
      }
      // extraLocations
      // extraConfig);

  # Creates a cloudflared tunnel ingress entry
  mkCloudflaredIngress = {
    subdomain,
    domain ? "example.com",
    target,
  }: let
    hostname = "${subdomain}.${domain}";
  in
    lib.nameValuePair hostname target;

  # Standard nginx recommended settings
  recommendedNginxSettings = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };
}
