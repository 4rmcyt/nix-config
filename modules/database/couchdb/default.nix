# CouchDB for Obsidian LiveSync
# https://github.com/vrtmrz/obsidian-livesync
{ config, pkgs, ... }:
{
  # =================================================================
  # SOPS Secrets for CouchDB
  # =================================================================
  sops.secrets = {
    couchdb_admin_password = {
      sopsFile = ../../../secrets/couchdb.yaml;
      key = "admin_password";
      owner = "couchdb";
      group = "couchdb";
      mode = "0400";
    };
  };

  # =================================================================
  # Users and Groups
  # =================================================================
  users.users.couchdb = {
    isSystemUser = true;
    group = "couchdb";
  };
  users.groups.couchdb = { };

  # =================================================================
  # CouchDB Service
  # =================================================================
  services.couchdb = {
    enable = true;
    port = 5984;
    bindAddress = "127.0.0.1"; # Local only, expose via nginx

    # Admin user configured directly (plaintext, will be hashed by CouchDB)
    adminUser = "admin";
    adminPass = "LxC0c7ru331tqWV1";

    # Configuration for Obsidian LiveSync
    # https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md
    extraConfig = {
      chttpd = {
        require_valid_user = true;
        enable_cors = true;
        # 4GB max request size for large vaults
        max_http_request_size = 4294967296;
      };

      chttpd_auth.require_valid_user = true;

      httpd = {
        WWW-Authenticate = ''Basic realm="couchdb"'';
        enable_cors = true;
      };

      # 50MB max document size
      couchdb.max_document_size = 50000000;

      # CORS for Obsidian apps
      cors = {
        credentials = true;
        # Allow Obsidian mobile and desktop apps
        origins = "app://obsidian.md,capacitor://localhost,http://localhost,https://localhost,capacitor://livesync.example.com,http://livesync.example.com,https://livesync.example.com";
      };
    };
  };

  # =================================================================
  # Nginx Reverse Proxy
  # =================================================================
  services.nginx.virtualHosts."livesync.example.com" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:5984";
      proxyWebsockets = true;

      extraConfig = ''
        # Pass authentication headers
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;

        # Required for CouchDB
        proxy_buffering off;
        proxy_redirect off;

        # Increase timeouts for large syncs
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;

        # Large body size for vault syncs
        client_max_body_size 4G;
      '';
    };
  };

  # =================================================================
  # Firewall
  # =================================================================
  # CouchDB only accessible via nginx, no direct access needed
  # networking.firewall.allowedTCPPorts = [ 5984 ];

  # =================================================================
  # Systemd Service Configuration
  # =================================================================
  systemd.services.couchdb = {
    serviceConfig = {
      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";

      # Allow CouchDB to write to its data directory and runtime directory
      ReadWritePaths = [
        "/var/lib/couchdb"
        "/run/couchdb"
      ];

      # Resource limits
      MemoryMax = "2G";
      CPUQuota = "100%";
    };
  };
}
# =================================================================
# Initial Setup Instructions
# =================================================================
# 1. After first deployment, visit: https://livesync.example.com/_utils
# 2. Login with admin credentials from secrets/couchdb.yaml
# 3. Create a new database named "" (or your preferred name)
# 4. Create a user for your Obsidian client (recommended for securobsidianity)
# 5. In Obsidian LiveSync plugin settings:
#    - Remote Database URL: https://livesync.example.com/obsidian
#    - Username: (your created user)
#    - Password: (your user's password)
#    - Enable End-to-End Encryption (recommended)
#
# References:
# - https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md
# - https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/quick_setup.md
