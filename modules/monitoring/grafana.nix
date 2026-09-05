{config, ...}: {
  sops.secrets = {
    grafana_admin_password = {
      sopsFile = ../../secrets/grafana.yaml;
      key = "grafana_admin_password";
      owner = config.users.users.grafana.name;
    };
    grafana_db_password = {
      sopsFile = ../../secrets/postgresql.yaml;
      owner = config.users.users.postgres.name;
    };
    grafana_oidc_client_secret = {
      sopsFile = ../../secrets/kanidm.yaml;
      key = "kanidm_grafana_secret";
      owner = config.users.users.grafana.name;
    };
    grafana_secret_key = {
      sopsFile = ../../secrets/grafana.yaml;
      key = "grafana_secret_key";
      owner = config.users.users.grafana.name;
    };
  };

  users.users.grafana = {
    isSystemUser = true;
    description = "Grafana user";
    group = "grafana";
  };
  users.groups.grafana = {};

  networking.firewall.allowedTCPPorts = [config.my.network.ports.grafana];

  services.grafana = {
    enable = true;
    settings = {
      database = {
        type = "postgres";
        host = "/run/postgresql";
        user = "grafana";
        passwordFile = config.sops.secrets.grafana_db_password.path;
      };
      security = {
        admin_password_file = config.sops.secrets.grafana_admin_password.path;
        secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
      };
      server = {
        http_addr = "127.0.0.1";
        http_port = config.my.network.ports.grafana;
        root_url = "https://grafana.${config.my.defaults.domain}";
      };
      "auth.generic_oauth" = {
        enabled = true;
        name = "Kanidm";
        client_id = "grafana";
        client_secret = "$__file{${config.sops.secrets.grafana_oidc_client_secret.path}}";
        scopes = "openid profile email groups";
        auth_url = "https://idm.${config.my.defaults.domain}/ui/oauth2";
        token_url = "https://idm.${config.my.defaults.domain}/oauth2/token";
        api_url = "https://idm.${config.my.defaults.domain}/oauth2/openid/grafana/userinfo";
        use_pkce = true;
        role_attribute_path = "contains(grafana_role[], 'Admin') && 'GrafanaAdmin' || 'Viewer'";
        allow_assign_grafana_admin = true;
        allow_sign_up = true;
      };
    };
    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://localhost:${toString config.services.prometheus.port}";
        isDefault = true;
      }
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://localhost:${toString config.my.network.ports.loki}";
      }
    ];
    provision.dashboards.settings.providers = [
      {
        name = "dashboards";
        options.path = ./dashboards;
        disableDeletion = false;
        updateIntervalSeconds = 30;
      }
    ];
  };
}
