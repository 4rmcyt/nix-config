{
  config,
  lib,
  ...
}: let
  inherit (config.my.defaults) domain;

  # Service to port mapping
  services = {
    tdarr = 8265;
    paperless = 8000;
    cal = 5232;
    link = 3000;
    flare = 3001;
    grafana = 3002;
    kuma = 5681;
    hass = 8123;
    vault = 8200;
    ollama = 11434;
  };

  # Helper function to create nginx virtualHost
  mkNginxVirtualHost = {
    subdomain,
    port,
    domain ? config.my.defaults.domain,
    certPath ? config.my.security.ssl.certPath,
    keyPath ? config.my.security.ssl.keyPath,
    websockets ? true,
    extraLocations ? {},
    extraConfig ? {},
  }: let
    hostname = "${subdomain}.${domain}";
  in
    lib.nameValuePair hostname (
      {
        forceSSL = true;
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
      // extraConfig
    );

  # Generate nginx virtualHosts for all services
  virtualHosts = lib.listToAttrs (
    lib.mapAttrsToList (subdomain: port: mkNginxVirtualHost {inherit subdomain port;}) services
  );
in {
  config = {
    # SSL certificate paths configuration
    my.security.ssl = {
      certPath = "/var/lib/acme/${domain}/fullchain.pem";
      keyPath = "/var/lib/acme/${domain}/key.pem";
    };

    # ACME/Let's Encrypt configuration
    sops.secrets.cloudflare_acme_credentials = {
      sopsFile = ../../../secrets/cloudflare_acme_credentials.env;
      owner = "acme";
      group = "acme";
      mode = "0400";
      format = "dotenv";
    };

    users.users.acme = {
      isSystemUser = true;
      group = "acme";
    };
    users.groups.acme = {};

    security.acme = {
      acceptTerms = true;
      defaults.email = config.my.defaults.email;

      certs.${domain} = {
        domain = "*.${domain}";
        extraDomainNames = [domain];
        dnsProvider = "cloudflare";
        credentialsFile = config.sops.secrets.cloudflare_acme_credentials.path;
        keyType = "ec256";
        group = "traefik";
        postRun = "systemctl reload traefik.service";
      };
    };
  };
}
