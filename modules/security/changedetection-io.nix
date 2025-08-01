{ config, pkgs, ... }:

{
  services.changedetection-io = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 5001; # Default port for changedetection.io
    dataDir = "/var/lib/changedetection-io";
  };


  services.nginx.virtualHosts."changedetection.example.com" = {
    forceSSL = true;
    enableACME = true;
    extraConfig = ''
      auth_request /outpost.goauthentik.io/auth/nginx;
      error_page 401 = @goauthentik;
    '';

    locations."/" = {
      proxyPass = "http://127.0.0.1:5001";
      proxyWebsockets = true;
    };


    locations."/outpost.goauthentik.io" = {
      proxy_pass http://authentik-outpost.local:9000/outpost.goauthentik.io;
      proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    };
    locations."@goauthentik" = {
      return 302 https://authentik.example.com/outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
    };
  };

  users.users.changedetection-io = {
    isSystemUser = true;
    group = "changedetection-io";
    extraGroups = [ "users" "changedetection-io" ];
  };
  users.groups.changedetection-io = {};
}
