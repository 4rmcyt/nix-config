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
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.cloudflare_acme_credentials = import ../../../lib/cloudflare-acme-secret.nix "caddy";

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
        hash = "sha256-dQvk6ezY6TQ1J7PjhCXnThF/SqVgPwBO8/RXzHCY+js=";
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
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile =
      config.sops.secrets.cloudflare_acme_credentials.path;
  };
}
