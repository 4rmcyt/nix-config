{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    cloudflare_tunnel_credentials = {
      sopsFile = ../../../secrets/cloudflare_tunnel_credentials.bin;
      key = "credentials";
      owner = "cloudflared";
      group = "cloudflared";
      mode = "0400";
      format = "binary";
    };

    cloudflare_tunnel_id = {
      sopsFile = ../../../secrets/cloudflare.yaml;
      key = "cloudflare_tunnel_id";
      owner = "cloudflared";
      group = "cloudflared";
      mode = "0400";
    };
  };

  sops.templates."cloudflared-config.yml" = {
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
    content = ''
      tunnel: ${config.sops.placeholder.cloudflare_tunnel_id}
      credentials-file: ${config.sops.secrets.cloudflare_tunnel_credentials.path}

      # Enable WebSocket support for all services
      warp-routing:
        enabled: false

      # Global origin request settings
      originRequest:
        connectTimeout: 30s
        tcpKeepAlive: 30s
        keepAliveTimeout: 90s
        keepAliveConnections: 100
        noHappyEyeballs: false

      ingress:
        - hostname: hass.${config.my.defaults.domain}
          service: https://localhost:443
          originRequest:
            originServerName: hass.${config.my.defaults.domain}
            noTLSVerify: true

        - hostname: livesync.${config.my.defaults.domain}
          service: https://localhost:443
          originRequest:
            originServerName: livesync.${config.my.defaults.domain}
            noTLSVerify: true

        - hostname: cal.${config.my.defaults.domain}
          service: https://localhost:443
          originRequest:
            originServerName: cal.${config.my.defaults.domain}
            noTLSVerify: true

        - hostname: ntfy.${config.my.defaults.domain}
          service: https://localhost:443
          originRequest:
            originServerName: ntfy.${config.my.defaults.domain}
            noTLSVerify: true

        - hostname: jobko.${config.my.defaults.domain}
          service: https://localhost:443
          originRequest:
            originServerName: jobko.${config.my.defaults.domain}
            noTLSVerify: true

        - hostname: idm.${config.my.defaults.domain}
          service: https://localhost:443
          originRequest:
            originServerName: idm.${config.my.defaults.domain}
            noTLSVerify: true

        # Catch-all
        - service: http_status:404
    '';
  };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = {};

  systemd.services.cloudflared = {
    after = [
      "network.target"
      "network-online.target"
      "sops-nix.service"
    ];
    wants = [
      "network.target"
      "network-online.target"
    ];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      User = "cloudflared";
      Group = "cloudflared";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config ${
        config.sops.templates."cloudflared-config.yml".path
      } --no-autoupdate run";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
