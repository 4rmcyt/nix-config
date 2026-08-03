{
  config,
  pkgs,
  ...
}: let
  inherit (config.my.defaults) domain;
  port = 3013;
  certDir = "/var/lib/kanidm/tls";
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
    package = pkgs.kanidmWithSecretProvisioning_1_11;

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
      acceptInvalidCerts = true;
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
        originUrl = [
          "https://audiobookshelf.${domain}/auth/openid/callback"
          "audiobookshelf://oauth"
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

  services.traefik.dynamicConfigOptions.http = {
    routers.kanidm = {
      rule = "Host(`idm.${domain}`)";
      entryPoints = ["websecure"];
      service = "kanidm";
      middlewares = [
        "security-headers"
        "crowdsec"
      ];
      tls.certResolver = "default";
    };
    services.kanidm = {
      loadBalancer = {
        servers = [{url = "https://127.0.0.1:${toString port}";}];
        serversTransport = "kanidm-transport";
      };
    };
    serversTransports.kanidm-transport.insecureSkipVerify = true;
  };
}
