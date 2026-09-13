{
  config,
  lib,
  pkgs,
  mkProxiedRouter,
  ...
}: let
  inherit (config.my.defaults) domain;
  port = 3013;
  certDir = "/var/lib/kanidm/tls";
  kanidmVersion = import ./version.nix;
in {
  # Generate self-signed TLS cert for kanidm (it requires HTTPS natively)
  systemd.services.kanidm-tls-cert = {
    description = "Generate self-signed TLS certificate for Kanidm";
    before = ["kanidm.service"];
    wantedBy = ["kanidm.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p ${certDir}
      if [ ! -f ${certDir}/cert.pem ]; then
        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 -nodes \
          -keyout ${certDir}/key.pem \
          -out ${certDir}/cert.pem \
          -days 3650 \
          -subj "/CN=idm.${domain}"
        chown -R kanidm:kanidm ${certDir}
        chmod 750 ${certDir}
        chmod 640 ${certDir}/cert.pem ${certDir}/key.pem
      fi
    '';
  };

  services.kanidm = {
    package = pkgs."kanidmWithSecretProvisioning_${kanidmVersion}";

    client = {
      enable = true;
      settings.uri = "https://idm.${domain}";
    };

    server = {
      enable = true;
      settings = {
        bindaddress = "127.0.0.1:${toString port}";
        origin = "https://idm.${domain}";
        domain = "idm.${domain}";
        tls_chain = "${certDir}/cert.pem";
        tls_key = "${certDir}/key.pem";
        log_level = "info";
        http_client_address_info.x-forward-for = ["127.0.0.1"];
        online_backup = {
          path = "/var/lib/kanidm/backups";
          schedule = "0 3 * * *";
          versions = 7;
        };
      };
    };

    provision = {
      enable = true;
      # instanceUrl defaults to https://localhost:${port}, so
      # acceptInvalidCerts is already true by default — no need to set it.
      adminPasswordFile = config.sops.secrets.kanidm_admin_password.path;
      idmAdminPasswordFile = config.sops.secrets.kanidm_idm_admin_password.path;

      groups.users = {
        members = [config.my.defaults.user];
      };

      persons.${config.my.defaults.user} = {
        displayName = config.my.defaults.user;
        mailAddresses = [config.my.defaults.email];
        groups = ["users"];
      };

      systems.oauth2.headscale = {
        displayName = "Headscale";
        originUrl = "https://hs.${domain}/oidc/callback";
        originLanding = "https://hs.${domain}";
        basicSecretFile = config.sops.secrets.kanidm_headscale_secret.path;
        preferShortUsername = true;
        scopeMaps.users = [
          "openid"
          "profile"
          "email"
        ];
      };

      systems.oauth2.grafana = {
        displayName = "Grafana";
        originUrl = "https://grafana.${domain}/login/generic_oauth";
        originLanding = "https://grafana.${domain}";
        basicSecretFile = config.sops.secrets.kanidm_grafana_secret.path;
        preferShortUsername = true;
        scopeMaps.users = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        claimMaps.grafana_role = {
          joinType = "array";
          valuesByGroup.users = ["Admin"];
        };
      };

      systems.oauth2.miniflux = {
        displayName = "Miniflux";
        originUrl = "https://miniflux.${domain}/oauth2/oidc/callback";
        originLanding = "https://miniflux.${domain}";
        basicSecretFile = config.sops.secrets.kanidm_miniflux_secret.path;
        preferShortUsername = true;
        scopeMaps.users = [
          "openid"
          "profile"
          "email"
        ];
        claimMaps.groups = {
          joinType = "array";
          valuesByGroup.users = ["admin"];
        };
      };

      systems.oauth2.audiobookshelf = {
        displayName = "Audiobookshelf";
        # Only ABS's own server callbacks go here. Custom mobile-app URI
        # schemes (e.g. audiobookshelf://oauth) are registered inside ABS
        # itself (Settings > Allowed Mobile Redirect URIs), not with the
        # OIDC provider — see audiobookshelf.org/docs/.../oidc-authentication
        originUrl = [
          "https://audiobookshelf.${domain}/auth/openid/callback"
          "https://audiobookshelf.${domain}/auth/openid/mobile-redirect"
        ];
        originLanding = "https://audiobookshelf.${domain}";
        basicSecretFile = config.sops.secrets.kanidm_audiobookshelf_secret.path;
        preferShortUsername = true;
        scopeMaps.users = [
          "openid"
          "profile"
          "email"
        ];
        claimMaps.groups = {
          joinType = "array";
          valuesByGroup.users = ["admin"];
        };
      };

      systems.oauth2.jellyfin = {
        displayName = "Jellyfin";
        originUrl = "https://jellyfin.${domain}/sso/OID/redirect/kanidm";
        originLanding = "https://jellyfin.${domain}";
        basicSecretFile = config.sops.secrets.kanidm_jellyfin_secret.path;
        preferShortUsername = true;
        scopeMaps.users = [
          "openid"
          "profile"
          "email"
        ];
        claimMaps.groups = {
          joinType = "array";
          valuesByGroup.users = ["admin"];
        };
      };
    };
  };

  sops.secrets = {
    kanidm_admin_password = {
      sopsFile = ../../../secrets/kanidm.yaml;
      owner = "kanidm";
      mode = "0400";
    };
    kanidm_idm_admin_password = {
      sopsFile = ../../../secrets/kanidm.yaml;
      owner = "kanidm";
      mode = "0400";
    };
    kanidm_headscale_secret = {
      sopsFile = ../../../secrets/kanidm.yaml;
      owner = "kanidm";
      mode = "0400";
    };
    kanidm_grafana_secret = {
      sopsFile = ../../../secrets/kanidm.yaml;
      owner = "kanidm";
      mode = "0400";
    };
    kanidm_miniflux_secret = {
      sopsFile = ../../../secrets/kanidm.yaml;
      owner = "kanidm";
      mode = "0400";
    };
    kanidm_audiobookshelf_secret = {
      sopsFile = ../../../secrets/kanidm.yaml;
      owner = "kanidm";
      mode = "0400";
    };
    kanidm_jellyfin_secret = {
      sopsFile = ../../../secrets/kanidm.yaml;
      owner = "kanidm";
      mode = "0400";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kanidm 0750 kanidm kanidm -"
    "d /var/lib/kanidm/backups 0750 kanidm kanidm -"
    "d /var/lib/kanidm/tls 0750 kanidm kanidm -"
  ];

  # nixpkgs' kanidm module already sets CapabilityBoundingSet=
  # cap_net_bind_service (matches AmbientCapabilities), a curated
  # SystemCallFilter, RestrictAddressFamilies=AF_INET/AF_INET6/AF_UNIX,
  # MemoryDenyWriteExecute=yes (already running fine — Kanidm is Rust, not
  # Go/BEAM, no JIT), and StateDirectory=kanidm (verified via `systemctl
  # show kanidm.service`) — don't touch those, they're already tight.
  # The one real gap: ProtectSystem was "no" — filesystem access is
  # completely unrestricted. StateDirectory already covers /var/lib/kanidm
  # (including the TLS cert dir kanidm-tls-cert writes to) even under
  # "strict", so this shouldn't need any extra ReadWritePaths.
  systemd.services.kanidm.serviceConfig = {
    ProtectSystem = lib.mkDefault "strict";
    ProtectHome = lib.mkDefault true;
    PrivateTmp = lib.mkDefault true;
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
    # PrivateUsers deliberately not set: same class of risk demonstrated
    # live on caddy/crowdsec-firewall-bouncer (breaks the kernel's
    # privileged-port check for AmbientCapabilities=CAP_NET_BIND_SERVICE
    # once the service is in its own user namespace) — kanidm has the exact
    # same ambient capability, for the exact same reason (binding via
    # Traefik's serversTransport doesn't apply here, kanidm itself binds
    # 127.0.0.1:3013 — unprivileged port, so this is precautionary, not
    # confirmed necessary, but not worth testing against the SSO for
    # Grafana/Miniflux/Jellyfin/Headscale/Audiobookshelf).
  };

  services.traefik.dynamicConfigOptions.http = mkProxiedRouter "kanidm" {
    inherit port;
    host = "idm.${domain}";
    scheme = "https";
    serversTransport.insecureSkipVerify = true;
  };
}
