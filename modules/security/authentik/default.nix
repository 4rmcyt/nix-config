{
  config,
  lib,
  ...
}: {
  sops.secrets = {
    # --- Authentik Secrets ---
    authentik_env = {
      sopsFile = ../../../secrets/authentik.env;
      owner = config.users.users.authentik.name;
      group = config.users.groups.authentik.name;
      mode = "0600";
      format = "dotenv";
    };

    authentik_gmail_password = lib.mkDefault {
      sopsFile = ../../../secrets/authentik.yaml;
      key = "gmail_password";
      owner = config.users.users.authentik.name;
      group = config.users.groups.authentik.name;
      mode = "0600";
    };
  };

  users.users.authentik = {
    isSystemUser = true;
    group = "authentik";
    extraGroups = ["users"];
  };
  users.groups.authentik = {};

  networking.firewall.allowedTCPPorts = [
    9000 # Authentik
    9300 # Prometheus Metrics
    3389 # LDAP
    6636 # LDAPS
  ];

  services.authentik = {
    enable = true;
    environmentFile = config.sops.secrets.authentik_env.path;
    createDatabase = false;
    settings = {
      log_level = "warning"; # Reduce log verbosity
      session_duration = "hours=1";
      postgresql = {
        user = "authentik";
        name = "authentik";
        host = "/run/postgresql";
      };
      email = {
        host = "smtp.gmail.com";
        port = 587;
        username = config.my.defaults.email;
        passwordeval = "cat ${config.sops.secrets.authentik_gmail_password.path}";
        use_tls = true;
        use_ssl = false;
        from = config.my.defaults.email;
      };
      disable_startup_analytics = true;
      avatars = "initials";
    };
  };
}
