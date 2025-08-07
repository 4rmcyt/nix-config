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
  security.acme.defaults.email = "4rmcyt@gmail.com";

  security.acme.certs."labhome.work" = {
    domain = "*.labhome.work";
    extraDomainNames = [ "labhome.work" ];
    dnsProvider = "cloudflare";
    credentialsFile = config.sops.secrets.cloudflare_acme_credentials.path;
    postRun = "systemctl reload nginx.service";
  };

  #  security.acme = {
  #   acceptTerms = true;
  #   defaults = {
  #     email = "admin@yourdomain.com";  # Set your email
      
  #     # Security: use DNS challenge for internal services
  #     dnsProvider = "cloudflare";  # Configure your DNS provider
  #     credentialsFile = config.sops.secrets.acme-credentials.path;
      
  #     # Security settings
  #     keyType = "ec256";  # Use elliptic curve keys
  #     reloadServices = [ "nginx" ];
      
  #     # Post-renewal hooks
  #     postRun = ''
  #       # Verify certificate
  #       ${pkgs.openssl}/bin/openssl x509 -in $RENEWED_LINEAGE/fullchain.pem -text -noout | grep -q "Issuer.*Let's Encrypt"
        
  #       # Log renewal
  #       echo "Certificate renewed for $RENEWED_DOMAINS" | ${pkgs.systemd}/bin/systemd-cat -t acme-renewal
  #     '';
  #   };
    
  #   certs = {
  #     "labhome.work" = {
  #       domain = "labhome.work";
  #       extraDomainNames = [
  #         "*.labhome.work"
  #         "jellyfin.labhome.work"
  #         "ha.labhome.work"
  #         "grafana.labhome.work"
  #       ];
        
  #       # Security: validate certificate
  #       postRun = ''
  #         # Check certificate validity
  #         ${pkgs.openssl}/bin/openssl x509 -in ${config.security.acme.certs."labhome.work".directory}/fullchain.pem -checkend 86400 -noout
  #         if [ $? -ne 0 ]; then
  #           echo "WARNING: Certificate expires within 24 hours" | ${pkgs.systemd}/bin/systemd-cat -t acme-warning -p warning
  #         fi
  #       '';
  #     };
  #   };
  # };
  
  # # SOPS secret for ACME credentials
  # sops.secrets.acme-credentials = {
  #   sopsFile = ../../../secrets/certificates.yaml;
  #   owner = "acme";
  #   group = "acme";
  #   mode = "0400";
  # };
  
  # # Certificate monitoring
  # systemd.services.certificate-monitor = {
  #   description = "Certificate Expiry Monitor";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = pkgs.writeShellScript "cert-monitor" ''
  #       CERT_DIR="/var/lib/acme"
        
  #       for cert_path in "$CERT_DIR"/*/fullchain.pem; do
  #         if [ -f "$cert_path" ]; then
  #           domain=$(basename $(dirname "$cert_path"))
            
  #           # Check expiry (30 days warning)
  #           if ! ${pkgs.openssl}/bin/openssl x509 -in "$cert_path" -checkend 2592000 -noout; then
  #             echo "WARNING: Certificate for $domain expires within 30 days" | \
  #               ${pkgs.systemd}/bin/systemd-cat -t cert-monitor -p warning
  #           fi
            
  #           # Check if certificate is valid
  #           if ! ${pkgs.openssl}/bin/openssl x509 -in "$cert_path" -noout -checkend 0; then
  #             echo "CRITICAL: Certificate for $domain has expired" | \
  #               ${pkgs.systemd}/bin/systemd-cat -t cert-monitor -p crit
  #           fi
  #         fi
  #       done
  #     '';
  #   };
  # };
  
  # systemd.timers.certificate-monitor = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Persistent = true;
  #     RandomizedDelaySec = "3600";
  #   };
  # };

}
# CLOUDFLARE_EMAIL,CLOUDFLARE_API_KEY, CLOUDFLARE_DNS_API_TOKEN,CLOUDFLARE_ZONE_API_TOKEN
