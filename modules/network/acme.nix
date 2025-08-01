{ config, pkgs, ... }:

{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "redacted@example.com";

  security.acme.certs."example.com" = {

    domain = "*.example.com";
    extraDomainNames = [ "example.com" ];

    dnsProvider = "cloudflare";
    credentialsFile = config.sops.secrets.cloudflare_api_token.path;

    postRun = "systemctl reload nginx.service";
  };

  

  users.users.acme = {
    isSystemUser = true;
    group = "acme";
    extraGroups = [
      "users"
      "acme"
    ];
  };
  users.groups.acme = { };
}
