{ config, pkgs, ... }:

{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "4rmcyt@gmail.com";

  security.acme.certs."labhome.work" = {

    domain = "*.labhome.work";
    extraDomainNames = [ "labhome.work" ];

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
