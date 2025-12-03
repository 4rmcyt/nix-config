{config, ...}: let
  domain = rec {
    root = "example.com";
    oauth2-proxy = "oauth2-proxy.${root}";
    sso = "auth.${root}";
  };
  # port = 4180;
  # realm = "homelab";
in {
  # =================================================================
  # Users and Groups
  # =================================================================
  users.groups.oauth2-proxy = {};
  users.users.oauth2-proxy = {
    isSystemUser = true;
    group = "oauth2-proxy";
  };
  users.groups.oauth2-proxy.members = ["nginx"];

  # =================================================================
  # SOPS Secrets
  # =================================================================
  # NOTE: You need to create secrets/oauth2-proxy.yaml with the following keys:
  # - OAUTH2_PROXY_CLIENT_ID
  # - OAUTH2_PROXY_CLIENT_SECRET
  # - OAUTH2_PROXY_COOKIE_SECRET
  sops.secrets.oauth2-proxy-secrets-env = {
    sopsFile = ../../../secrets/oauth2-proxy.env;
    owner = "oauth2-proxy";
    group = "oauth2-proxy";
    format = "dotenv";
    mode = "0400";
  };

  # =================================================================
  # Services
  # =================================================================
  services = {
    oauth2-proxy = {
      enable = true;

      cookie = {
        domain = ".${domain.root}";
        secure = true;
        expire = "12h";
      };
      reverseProxy = true;
      httpAddress = "unix:///run/oauth2-proxy/oauth2-proxy.sock";
      redirectURL = "https://${domain.oauth2-proxy}/oauth2/callback";
      setXauthrequest = true;
      extraConfig = {
        code-challenge-method = "S256";
        whitelist-domain = ".${domain.root}";
        set-authorization-header = true;
        pass-access-token = true;
        skip-jwt-bearer-tokens = true;
        upstream = "static://202";
      };
      keyFile = config.sops.secrets.oauth2-proxy-secrets-env.path;
    };

    nginx = {
      upstreams.oauth2-proxy = {
        servers."unix:/run/oauth2-proxy/oauth2-proxy.sock" = {};
        extraConfig = ''
          zone oauth2-proxy 64k;
          keepalive 2;
        '';
      };
      virtualHosts.${domain.root} = {
        forceSSL = true;
        useACMEWildcardHost = true;
        locations."/".proxyPass = "http://oauth2-proxy";

        locations."/oauth2/" = {
          proxyPass = "http://oauth2-proxy";
          extraConfig = ''
            proxy_set_header X-Scheme                $scheme;
            proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
          '';
        };
      };
    };
  };
  systemd.services.oauth2-proxy.serviceConfig = {
    RuntimeDirectory = "oauth2-proxy";
    RuntimeDirectoryMode = "0750";
    UMask = "007";
    RestartSec = "60"; # Retry every minute
  };
}
