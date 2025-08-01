{ config, pkgs, ... }:

{
  sops.secrets = {
    # --- Authentik Secrets ---
    authentik_secret_key = {
      sopsFile = ../../secrets/authentik.yaml;
      key = "authentik_secret_key";
      owner = config.users.users.authentik.name;
      group = config.users.groups.authentik.name;
      mode = "0400";
    };
    authentik_outpost_token = {
      sopsFile = ../../secrets/authentik.yaml;
      key = "authentik_outpost_token";
      owner = config.users.users.authentik.name;
      group = config.users.groups.authentik.name;
      mode = "0400";
    };
    authentik_env = {
      sopsFile = ../../secrets/authentik_env.yaml;
      owner = config.users.users.authentik.name;
      group = config.users.groups.authentik.name;
      mode = "0400";
      format = "dotenv";
    };
    authentik_ldap = {
      sopsFile = ../../secrets/authentik.yaml;
      key = "authentik_ldap";
      owner = config.users.users.authentik.name;
      group = config.users.groups.authentik.name;
      mode = "0400";
    };
    gmail_password = {
      sopsFile = ../../secrets/gmail_conf.yaml;
      key = "gmail_password";
    };
  };

  users.users.authentik = {
    isSystemUser = true;
    group = "authentik";
    extraGroups = [ "users" ];
  };
  users.groups.authentik = { };

  networking.firewall.allowedTCPPorts = [
    9000 # Authentik
    8080 # Authentik Outpost Proxy
    9100 # Authentik Metrics
    3389 # LDAP
    6636 # LDAPS

  ];

  services.nginx.virtualHosts."authentik.example.com" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "https://127.0.0.1:9000";
    };
  };

  services.authentik = {
    enable = true;
    environmentFile = config.sops.secrets.authentik_env.path;
    createDatabase = false;
    settings = {
      postgresql = {
        user = "authentik";
        name = "authentik";
        host = "/run/postgresql";
      };
      email = {
        host = "smtp.gmail.com";
        port = 587;
        username = "redacted@example.com";
        passwordeval = "cat ${config.sops.secrets.gmail_password.path}";
        use_tls = true;
        use_ssl = false;
        from = "redacted@example.com";
      };
      disable_startup_analytics = true;
      avatars = "initials";
    };
  };
  authentik-ldap = {
    enable = true;
    environmentFile = config.sops.secrets.authentik_ldap.path;
  };
}
