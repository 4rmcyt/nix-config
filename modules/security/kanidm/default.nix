{
  config,
  pkgs,
  ...
}: let
  inherit (config.my.defaults) domain;
  port = 3013;
in {
  services.kanidm = {
    package = pkgs.kanidmWithSecretProvisioning_1_10;

    server = {
      enable = true;
      settings = {
        bindaddress = "127.0.0.1:${toString port}";
        origin = "https://idm.${domain}";
        domain = "idm.${domain}";
        db_path = "/var/lib/kanidm/db.sqlite";
        log_level = "info";
        online_backup = {
          path = "/var/lib/kanidm/backups";
          schedule = "0 3 * * *";
          versions = 7;
        };
      };
    };

    provision = {
      enable = true;
      instanceUrl = "https://idm.${domain}";
      adminPasswordFile = config.sops.secrets.kanidm_admin_password.path;
      idmAdminPasswordFile = config.sops.secrets.kanidm_idm_admin_password.path;

      persons.${config.my.defaults.user} = {
        displayName = config.my.defaults.user;
        mailAddresses = [config.my.defaults.email];
        groups = ["idm_admins"];
      };

      systems.oauth2.headscale = {
        displayName = "Headscale";
        originUrl = "https://hs.${domain}/oidc/callback";
        originLanding = "https://hs.${domain}";
        basicSecretFile = config.sops.secrets.kanidm_headscale_secret.path;
        preferShortUsername = true;
        scopeMaps."idm_all_persons" = [
          "openid"
          "profile"
          "email"
        ];
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
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kanidm 0750 kanidm kanidm -"
    "d /var/lib/kanidm/backups 0750 kanidm kanidm -"
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
    services.kanidm.loadBalancer.servers = [{url = "http://127.0.0.1:${toString port}";}];
  };
}
