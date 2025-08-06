{ config, pkgs, ... }:

{
  sops.secrets = {
    cloudflare_acme_credentials = {
      sopsFile = ../../../secrets/cloudflare_acme_credentials.env;
      owner = config.users.users.acme.name;
      group = config.users.groups.acme.name;
      mode = "0400";
      format = "dotenv";
    };
  };

  users.users.acme = {
    isSystemUser = true;
    group = "acme";
  };
  users.groups.acme = { };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "redacted@example.com";

  security.acme.certs."example.com" = {
    domain = "*.example.com";
    extraDomainNames = [ "example.com" ];
    dnsProvider = "cloudflare";
    credentialsFile = config.sops.secrets.cloudflare_acme_credentials.path;
    postRun = "systemctl reload nginx.service";
  };

}
# CLOUDFLARE_EMAIL,CLOUDFLARE_API_KEY, CLOUDFLARE_DNS_API_TOKEN,CLOUDFLARE_ZONE_API_TOKEN
