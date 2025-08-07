{ config, pkgs, ... }:
{
  users.users.nginx = {
    isSystemUser = true;
    group = "acme";
    extraGroups = [
      "users"
      "acme"
    ];
  };
  users.groups.nginx = { };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };

  services.nginx = {
    enable = true;
    group = "nginx";
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    statusPage = true;
  };

  #   recommendedGzipSettings = true;
  #   recommendedOptimisation = true;
  #   recommendedProxySettings = true;
  #   recommendedTlsSettings = true;

  #   # Additional security
  #   serverTokens = false;  # Hide nginx version

  #   # Rate limiting
  #   commonHttpConfig = ''
  #     # Rate limiting zones
  #     limit_req_zone $binary_remote_addr zone=auth:10m rate=1r/s;
  #     limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
  #     limit_req_zone $binary_remote_addr zone=general:10m rate=5r/s;

  #     # Security headers
  #     add_header X-Frame-Options DENY always;
  #     add_header X-Content-Type-Options nosniff always;
  #     add_header X-XSS-Protection "1; mode=block" always;
  #     add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  #     add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;

  #     # Hide server information
  #     server_tokens off;
  #     more_clear_headers Server;

  #     # Client limits
  #     client_max_body_size 100M;
  #     client_body_timeout 60s;
  #     client_header_timeout 60s;
  #   '';

  #   virtualHosts = {
  #     # Remove any default or catch-all hosts
  #     "_" = {
  #       default = true;
  #       extraConfig = ''
  #         return 444;  # Drop connection for unknown hosts
  #       '';
  #     };

  #     # Specific service configurations with security
  #     "jellyfin.labhome.work" = {
  #       forceSSL = true;
  #       sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
  #       sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";

  #       locations."/" = {
  #         proxyPass = "http://127.0.0.1:8096";
  #         extraConfig = ''
  #           # Rate limiting
  #           limit_req zone=general burst=20 nodelay;

  #           # Security headers specific to Jellyfin
  #           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  #           proxy_set_header X-Forwarded-Proto $scheme;
  #           proxy_set_header X-Forwarded-Host $http_host;

  #           # WebSocket support
  #           proxy_http_version 1.1;
  #           proxy_set_header Upgrade $http_upgrade;
  #           proxy_set_header Connection "upgrade";

  #           # Timeouts
  #           proxy_connect_timeout 30s;
  #           proxy_send_timeout 30s;
  #           proxy_read_timeout 300s;
  #         '';
  #       };
  #     };
  #   };
  # };

  # # Add fail2ban for nginx
  # services.fail2ban = {
  #   enable = true;
  #   jails = {
  #     nginx-http-auth = ''
  #       enabled = true
  #       port = http,https
  #       filter = nginx-http-auth
  #       logpath = /var/log/nginx/error.log
  #       maxretry = 3
  #       bantime = 3600
  #     '';

  #     nginx-noscript = ''
  #       enabled = true
  #       port = http,https
  #       filter = nginx-noscript
  #       logpath = /var/log/nginx/access.log
  #       maxretry = 6
  #       bantime = 86400
  #     '';
  #   };
  # };
}
