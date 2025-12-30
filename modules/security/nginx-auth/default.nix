{config, ...}: let
  inherit (config.my.defaults) domain;
  proxyPort = 4180;

  # Helper function to add OAuth2 authentication to nginx locations
  mkAuthLocation = upstream: {
    proxyPass = upstream;
    proxyWebsockets = true;
    extraConfig = ''
      # OAuth2 Proxy authentication
      auth_request /oauth2/auth;
      error_page 401 = /oauth2/sign_in;

      # Pass OAuth2 Proxy authentication headers to backend
      auth_request_set $user $upstream_http_x_auth_request_user;
      auth_request_set $email $upstream_http_x_auth_request_email;
      proxy_set_header X-User $user;
      proxy_set_header X-Email $email;
      proxy_set_header X-Auth-Request-User $user;
      proxy_set_header X-Auth-Request-Email $email;

      # Handle redirects
      auth_request_set $auth_cookie $upstream_http_set_cookie;
      add_header Set-Cookie $auth_cookie;
    '';
  };

  # OAuth2 Proxy callback and auth endpoints
  oauth2ProxyLocations = {
    "/oauth2/" = {
      proxyPass = "http://127.0.0.1:${toString proxyPort}";
      extraConfig = ''
        proxy_set_header X-Scheme $scheme;
        proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
      '';
    };
    "= /oauth2/auth" = {
      proxyPass = "http://127.0.0.1:${toString proxyPort}";
      extraConfig = ''
        internal;
        proxy_set_header X-Scheme $scheme;
        proxy_set_header X-Original-URI $request_uri;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header Content-Length "";
        proxy_pass_request_body off;
      '';
    };
  };
in {
  # This module adds OAuth2 authentication to all nginx virtual hosts
  # It works by intercepting requests and checking authentication via oauth2-proxy
  # Note: Base nginx configuration is in modules/networking/nginx/default.nix

  services.nginx.virtualHosts = {
    # Keycloak authentication server
    "auth.${domain}" = {
      forceSSL = true;
      sslCertificate = config.my.security.ssl.certPath;
      sslCertificateKey = config.my.security.ssl.keyPath;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.keycloak.settings.http-port}";
        proxyWebsockets = true;

        extraConfig = ''
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Forwarded-Port $server_port;

          # Increase buffer sizes for Keycloak
          proxy_buffer_size 128k;
          proxy_buffers 4 256k;
          proxy_busy_buffers_size 256k;
        '';
      };
    };
    # Homepage Dashboard
    "home.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:8082";
        };
    };

    # Kavita
    "kavita.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:5000";
        };
    };

    # Microbin
    "microbin.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:8069";
        };
    };

    # Miniflux
    "miniflux.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:8086";
        };
    };

    # Jellyfin
    "jellyfin.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:8096";
        };
    };

    # Sonarr
    "sonarr.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:8989";
        };
    };

    # Radarr
    "radarr.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:7878";
        };
    };

    # Prowlarr
    "prowlarr.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:9696";
        };
    };

    # Bazarr
    "bazarr.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:6767";
        };
    };

    # Lidarr
    "lidarr.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:8686";
        };
    };

    # Readarr
    "readarr.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:8787";
        };
    };

    # Jellyseerr
    "jellyseerr.${domain}" = {
      locations =
        oauth2ProxyLocations
        // {
          "/" = mkAuthLocation "http://localhost:5055";
        };
    };
  };
}
