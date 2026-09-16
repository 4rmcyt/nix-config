{
  config,
  lib,
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

    # Temporary; postStart below replaces it with the real admin password.
    adminUser = "admin";
    adminPass = "-";

    extraConfig = {
      chttpd = {
        require_valid_user = true;
        enable_cors = true;
        max_http_request_size = 4294967296; # 4GB, for large vaults
      };

      chttpd_auth.require_valid_user = true;

      httpd = {
        WWW-Authenticate = ''Basic realm="couchdb"'';
        enable_cors = true;
      };

      couchdb.max_document_size = 50000000;

      cors = {
        credentials = true;
        origins = "app://obsidian.md,capacitor://localhost,http://localhost,https://localhost,capacitor://livesync.${config.my.defaults.domain},http://livesync.${config.my.defaults.domain},https://livesync.${config.my.defaults.domain}";
      };
    };
  };

  # No firewall exception needed: bindAddress=127.0.0.1 means Traefik reaches
  # this over loopback, not through the firewall.
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

      sleep 2

      ${pkgs.curl}/bin/curl -X PUT http://admin:$ADMIN_PASS@127.0.0.1:5984/_users || true

      ${pkgs.curl}/bin/curl -X PUT http://admin:$ADMIN_PASS@127.0.0.1:5984/_replicator || true
    '';

    serviceConfig =
      {
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      }
      // {
        ReadWritePaths = [
          "/var/lib/couchdb"
          "/run/couchdb"
        ];

        MemoryMax = "2G";
        CPUQuota = "100%";

        # nixpkgs' module leaves CapabilityBoundingSet at the full default set;
        # safe to clear since CouchDB requests no capability, runs as its own user.
        CapabilityBoundingSet = lib.mkForce "";
        RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX"];
        ProtectClock = lib.mkDefault true;
        ProtectKernelLogs = lib.mkDefault true;
        ProtectKernelModules = lib.mkDefault true;
        ProtectKernelTunables = lib.mkDefault true;
        ProtectControlGroups = lib.mkDefault true;
        ProtectHostname = lib.mkDefault true;
        RestrictNamespaces = lib.mkDefault true;
        RestrictSUIDSGID = lib.mkDefault true;
        LockPersonality = lib.mkDefault true;
        RestrictRealtime = lib.mkDefault true;
        ProtectProc = lib.mkDefault "invisible";
        ProcSubset = lib.mkDefault "pid";
        UMask = lib.mkDefault "0077";
        RemoveIPC = lib.mkDefault true;
        # Deliberately NOT setting SystemCallFilter/MemoryDenyWriteExecute/PrivateUsers:
        # CouchDB's BEAM VM JIT (BeamAsm) needs W+X memory — same risk class that
        # killed alloy.service (Go) on gcp-relay.
      };
  };
}
