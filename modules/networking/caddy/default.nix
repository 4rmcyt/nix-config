{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.caddy;
  inherit (config.my.defaults) domain email;
in {
  options.my.caddy = {
    enable = lib.mkEnableOption "Caddy reverse proxy with Cloudflare DNS-01";

    headscale.enable = lib.mkEnableOption "Caddy vhost for headscale";
    headplane = {
      enable = lib.mkEnableOption "Caddy vhost for headplane UI";
      tailscaleIp = lib.mkOption {
        type = lib.types.str;
        description = "Tailscale IP of this host — headplane vhost binds here so remote_ip is always 100.64.x.x";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.cloudflare_acme_credentials = {
      sopsFile = ../../../secrets/cloudflare_acme_credentials.env;
      owner = "caddy";
      group = "caddy";
      mode = "0400";
      format = "dotenv";
    };

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
        hash = "sha256-8yZDrejNKsaUnUaTUFYbarWNmxafqp2z2rWo+XRsxV8=";
      };
      globalConfig = ''
        email ${email}
      '';

      # https://hs.<domain> → headscale :8080 (Tailscale control protocol)
      #
      # Caddy instead of Traefik: Traefik drops the non-standard Upgrade header
      # required by the Tailscale control protocol.
      virtualHosts."hs.${domain}" = lib.mkIf cfg.headscale.enable {
        extraConfig = ''
          tls {
            dns cloudflare {env.CLOUDFLARE_DNS_API_TOKEN}
            resolvers 1.1.1.1
          }

          reverse_proxy 127.0.0.1:${toString config.services.headscale.port} {
            transport http {
              keepalive off
              compression off
            }
          }
        '';
      };

      # Tailscale-only vhost: binds on tailscale0, so remote_ip is always 100.64.x.x
      virtualHosts."hp.${domain}" = lib.mkIf cfg.headplane.enable {
        listenAddresses = [cfg.headplane.tailscaleIp];
        extraConfig = ''
          tls {
            dns cloudflare {env.CLOUDFLARE_DNS_API_TOKEN}
            resolvers 1.1.1.1
          }

          redir / /admin/ permanent
          reverse_proxy 127.0.0.1:${toString config.services.headplane.settings.server.port}
        '';
      };
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile =
      config.sops.secrets.cloudflare_acme_credentials.path;
  };
}
