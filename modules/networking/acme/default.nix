{ config, pkgs, ... }:

{
  sops.secrets = {
    cloudflare_api_token = {
      sopsFile = ../../../secrets/cloudflare.yaml;
      key = "cloudflare_api_key";
      group = config.users.groups.acme.name;
      mode = "0440";
    };
  };

  users.users.acme = {
    isSystemUser = true;
    group = "acme";
    extraGroups = [
      "acme"
    ];
  };
  users.groups.acme = { };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "redacted@example.com";

  security.acme.certs."example.com" = {
    domain = "*.example.com";
    extraDomainNames = [ "example.com" ];
    dnsProvider = "cloudflare";
    credentialsFile = config.sops.secrets.cloudflare_api_token.path;
    postRun = "systemctl reload nginx.service";
  };

}
# CLOUDFLARE_EMAIL,CLOUDFLARE_API_KEY, CLOUDFLARE_DNS_API_TOKEN,CLOUDFLARE_ZONE_API_TOKEN