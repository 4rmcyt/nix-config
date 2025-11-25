{
  config,
  pkgs,
  lib,
  ...
}: let
  serviceName = "keycloak";
  serviceUser = serviceName;
  serviceGroup = serviceName;
  dataDir = "/var/lib/${serviceName}";
in {
  # Import OAuth2 Proxy and nginx authentication modules
  imports = [
    ./oauth2-proxy.nix
    ./nginx-auth.nix
  ];
  # =================================================================
  # 1. SOPS Secrets
  # =================================================================
  sops.secrets = {
    keycloak_db_password = {
      sopsFile = ../../../secrets/keycloak.yaml;
      key = "db_password";
      owner = "postgres";
      mode = "0400";
    };
    keycloak_admin_password = {
      sopsFile = ../../../secrets/keycloak.yaml;
      key = "admin_password";
      owner = serviceUser;
      group = serviceGroup;
      mode = "0400";
    };
  };

  # =================================================================
  # 2. Users and Groups
  # =================================================================
  users.groups.${serviceGroup} = {};
  users.users.${serviceUser} = {
    isSystemUser = true;
    group = serviceGroup;
    home = dataDir;
  };

  # =================================================================
  # 3. Firewall
  # =================================================================
  networking.firewall.allowedTCPPorts = [
    8080 # Keycloak HTTP (behind nginx)
  ];

  # =================================================================
  # 4. PostgreSQL Database Setup
  # =================================================================
  services.postgresql = {
    enable = true;
    ensureDatabases = ["keycloak"];
    ensureUsers = [
      {
        name = "keycloak";
        ensureDBOwnership = true;
      }
    ];
  };

  # Set database password via systemd oneshot service
  systemd.services.keycloak-db-init = {
    description = "Initialize Keycloak Database Password";
    wantedBy = ["multi-user.target"];
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };
    script = ''
      PASSWORD=$(cat ${config.sops.secrets.keycloak_db_password.path})
      ${config.services.postgresql.package}/bin/psql -tAc "ALTER USER keycloak WITH PASSWORD '$PASSWORD';"
    '';
  };

  # =================================================================
  # 5. Keycloak Service
  # =================================================================
  services.keycloak = {
    enable = true;

    database = {
      type = "postgresql";
      host = "localhost";
      port = 5432;
      name = "keycloak";
      username = "keycloak";
      passwordFile = config.sops.secrets.keycloak_db_password.path;
      createLocally = false; # We manage it via PostgreSQL
    };

    settings = {
      hostname = "auth.${config.my.defaults.domain}";
      http-host = "127.0.0.1";
      http-port = 8080;
      proxy-headers = "xforwarded";
      http-enabled = true;
      hostname-strict-https = false;

      # Production optimizations
      cache = "ispn";
      cache-stack = "tcp";

      # Logging
      log-level = "INFO";

      # Health and metrics
      health-enabled = true;
      metrics-enabled = true;
    };

    # Themes and customization
    themes = {
      # You can add custom themes here
    };
  };

  # Set admin credentials
  systemd.services.keycloak.serviceConfig = {
    LoadCredential = [
      "admin_password:${config.sops.secrets.keycloak_admin_password.path}"
    ];

    # Security hardening
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectHome = true;
    ProtectSystem = "strict";
    ReadWritePaths = [dataDir];

    # Resource limits
    MemoryMax = "2G";
    CPUQuota = "200%";
    TasksMax = 500;
  };

  # Override environment to set admin password
  systemd.services.keycloak.environment = {
    KEYCLOAK_ADMIN = "admin";
    KEYCLOAK_ADMIN_PASSWORD_FILE = config.sops.secrets.keycloak_admin_password.path;
  };

  # =================================================================
  # 6. Nginx Reverse Proxy
  # =================================================================
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."auth.${config.my.defaults.domain}" = {
      forceSSL = true;
      sslCertificate = config.my.security.ssl.certPath;
      sslCertificateKey = config.my.security.ssl.keyPath;

      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;

        extraConfig = ''
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Forwarded-Port $server_port;

          # Increase buffer sizes for Keycloak
          proxy_buffer_size 128k;
          proxy_buffers 4 256k;
          proxy_busy_buffers_size 256k;
        '';
      };
    };
  };

  # =================================================================
  # 7. Directory Permissions
  # =================================================================
  systemd.tmpfiles.rules = [
    "d ${dataDir} 750 ${serviceUser} ${serviceGroup} - -"
    "d ${dataDir}/data 750 ${serviceUser} ${serviceGroup} - -"
    "d ${dataDir}/themes 750 ${serviceUser} ${serviceGroup} - -"
  ];

  # =================================================================
  # 8. Backup Configuration
  # =================================================================
  services.borgmatic.settings.source_directories = lib.mkAfter [
    dataDir
  ];

  # =================================================================
  # 9. Environment Configuration
  # =================================================================
  environment.systemPackages = with pkgs; [
    # Keycloak admin CLI tools
    keycloak
  ];
}
