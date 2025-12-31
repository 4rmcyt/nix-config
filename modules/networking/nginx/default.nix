{config, ...}: let
  inherit (config.my.defaults) domain;
in {
  # SSL certificate paths configuration for Traefik
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
}
