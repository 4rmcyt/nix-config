# CouchDB for Obsidian LiveSync
# https://github.com/vrtmrz/obsidian-livesync
{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    couchdb_admin_password = {
      sopsFile = ../../../secrets/couchdb.yaml;
      key = "admin_password";
      owner = "couchdb";
      group = "couchdb";
      mode = "0400";
    };
  };

  users.users.couchdb = {
    isSystemUser = true;
    group = "couchdb";
  };
  users.groups.couchdb = {};

  services.couchdb = {
    enable = true;
    port = 5984;
    bindAddress = "127.0.0.1";

    # Temporary admin to allow startup - will be replaced by postStart
    adminUser = "admin";
    adminPass = "-"; # Placeholder, will be set via postStart

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

      couchdb.max_document_size = 50000000;

      cors = {
        credentials = true;
        # Allow Obsidian mobile and desktop apps
        origins = "app://obsidian.md,capacitor://localhost,http://localhost,https://localhost,capacitor://livesync.${config.my.defaults.domain},http://livesync.${config.my.defaults.domain},https://livesync.${config.my.defaults.domain}";
      };
    };
  };

  # No firewall exception needed: bindAddress = "127.0.0.1" above means
  # nothing ever listens on a non-loopback interface; Traefik reaches it
  # over loopback, not through the firewall.

  systemd.services.couchdb = {
    postStart = ''
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s http://admin:-@127.0.0.1:5984/ > /dev/null 2>&1; then
          break
        fi
        sleep 1
      done

      ADMIN_PASS=$(cat ${config.sops.secrets.couchdb_admin_password.path})
      ${pkgs.curl}/bin/curl -X PUT http://admin:-@127.0.0.1:5984/_node/_local/_config/admins/admin \
        -H "Content-Type: application/json" \
        -d "\"$ADMIN_PASS\"" || true

      # Wait a moment for password to be updated
      sleep 2

      ${pkgs.curl}/bin/curl -X PUT http://admin:$ADMIN_PASS@127.0.0.1:5984/_users || true

      ${pkgs.curl}/bin/curl -X PUT http://admin:$ADMIN_PASS@127.0.0.1:5984/_replicator || true
    '';

    serviceConfig =
      config.my.hardening.serviceBase
      // {
        # Allow CouchDB to write to its data directory and runtime directory
        ReadWritePaths = [
          "/var/lib/couchdb"
          "/run/couchdb"
        ];

        MemoryMax = "2G";
        CPUQuota = "100%";
      };
  };
}
# Initial Setup Instructions
# 1. After first deployment, visit: https://livesync.${config.my.defaults.domain}/_utils
# 2. Login with admin credentials from secrets/couchdb.yaml
# 3. Create a new database named "" (or your preferred name)
# 4. Create a user for your Obsidian client (recommended for securobsidianity)
# 5. In Obsidian LiveSync plugin settings:
#    - Remote Database URL: https://livesync.${config.my.defaults.domain}/obsidian
#    - Username: (your created user)
#    - Password: (your user's password)
#    - Enable End-to-End Encryption (recommended)
#
# References:
# - https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md
# - https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/quick_setup.md

