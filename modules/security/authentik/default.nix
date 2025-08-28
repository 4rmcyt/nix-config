{
  config,
  lib,
  ...
}:
{
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
    extraGroups = [ "users" ];
  };
  users.groups.authentik = { };

  networking.firewall.allowedTCPPorts = [
    9000 # Authentik
    9300 # Prometheus Metrics
    3389 # LDAP
    6636 # LDAPS
  ];

  # services.nginx = {
  #   enable = true;
  #   recommendedGzipSettings = true;
  #   recommendedOptimisation = true;
  #   recommendedProxySettings = true;
  #   recommendedTlsSettings = true;
  #   virtualHosts."authentik.example.com" = {
  #     forceSSL = true;
  #     sslCertificate = "/var/lib/acme/example.com/fullchain.pem";
  #     sslCertificateKey = "/var/lib/acme/example.com/key.pem";
  #     locations."/" = {
  #       proxyWebsockets = true;
  #       proxyPass = "http://127.0.0.1:9000";
  #     };
  #   };
  # };
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
        username = "redacted@example.com";
        passwordeval = "cat ${config.sops.secrets.authentik_gmail_password.path}";
        use_tls = true;
        use_ssl = false;
        from = "redacted@example.com";
      };
      disable_startup_analytics = true;
      avatars = "initials";
    };

    # systemd.services.authentik = {
    #   serviceConfig = {
    #     # Resource limits
    #     MemoryMax = "1G";
    #     CPUQuota = "100%";
    #   };
    # };
  };
}
