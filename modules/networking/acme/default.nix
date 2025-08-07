{ config, pkgs, ... }:

{
  config = {
    sops.secrets.cloudflare_acme_credentials = {
      sopsFile = ../../../secrets/cloudflare_acme_credentials.env;
      owner = config.users.users.acme.name;
      group = config.users.groups.acme.name;
      mode = "0400";
      format = "dotenv";
    };

    users.users.acme = {
      isSystemUser = true;
      group = "acme";
    };
    users.groups.acme = { };

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "4rmcyt@gmail.com";

    security.acme.certs."labhome.work" = {
      domain = "*.labhome.work";
      extraDomainNames = [ "labhome.work" ];
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets.cloudflare_acme_credentials.path;
      postRun = "systemctl reload nginx.service";
    };
  };
}