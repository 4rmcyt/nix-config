{ config, pkgs, ... }:

{
  # =================================================================
  # Set the value for our new system-wide SSL path options
  # =================================================================
  config.my.security.ssl = {
    certPath = "/var/lib/acme/example.com/fullchain.pem";
    keyPath = "/var/lib/acme/example.com/key.pem";
  };
  
  # =================================================================
  # SOPS Secrets & User
  # This part is already excellent.
  # =================================================================
  sops.secrets.cloudflare_acme_credentials = {
    sopsFile = ../../../secrets/cloudflare_acme_credentials.env;
    owner = config.users.users.acme.name;
    mode = "0400";
    format = "dotenv";
  };
  users.users.acme = {
    isSystemUser = true;
    group = "acme";
  };
  users.groups.acme = {};

  # =================================================================
  # ACME Certificate Configuration
  # =================================================================
  security.acme = {
    acceptTerms = true;
    defaults.email = "redacted@example.com";
    
    certs."example.com" = {
      domain = "*.example.com";
      extraDomainNames = [ "example.com" ];
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets.cloudflare_acme_credentials.path;
      
      # IMPROVEMENT: Use a modern, faster key type.
      keyType = "ec256";
      
      # IMPROVEMENT: Give the nginx group access to the certificate.
      # This is a critical security best practice.
      group = "nginx";
      
      # Reload Nginx after a successful renewal.
      postRun = "systemctl reload nginx.service";
    };
  };
}