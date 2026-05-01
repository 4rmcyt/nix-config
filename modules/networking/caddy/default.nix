{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.caddy;
  inherit (config.my.defaults) domain email;
in
{
  options.my.caddy = {
    enable = lib.mkEnableOption "Caddy reverse proxy";
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
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
        hash = "sha256-J0HWjCPoOoARAxDpG2bS9c0x5Wv4Q23qWZbTjd8nW84=";
      };

      globalConfig = ''
        email ${email}
      '';

      virtualHosts."dify.${domain}".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_DNS_API_TOKEN} {
            zone_id {env.CLOUDFLARE_ZONE_ID}
          }
        }

        @api path /console/api* /api* /v1* /files*
        reverse_proxy @api localhost:5001

        reverse_proxy localhost:3000
      '';
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile =
      config.sops.secrets.cloudflare_acme_credentials.path;
  };
}
