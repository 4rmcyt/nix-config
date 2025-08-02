{ config, pkgs, ... }:

{
  sops.secrets = {
    # --- Authentik Secrets ---
    authentik_env = {
      sopsFile = ../../../secrets/authentik_env;
      owner = config.users.users.authentik.name;
      group = config.users.groups.authentik.name;
      mode = "0400";
      format = "binary";
    };

    gmail_password = {
      sopsFile = ../../../secrets/authentik.yaml;
      key = "gmail_password";
      owner = config.users.users.authentik.name;
      group = config.users.groups.authentik.name;
      mode = "0400";
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
    9300 # Prometheus Metrics
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."authentik.labhome.work" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "https://127.0.0.1:9000";
      };
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
        username = "4rmcyt@gmail.com";
        passwordeval = "cat ${config.sops.secrets.gmail_password.path}";
        use_tls = true;
        use_ssl = false;
        from = "4rmcyt@gmail.com";
      };
      disable_startup_analytics = true;
      avatars = "initials";
    };
  };
}
