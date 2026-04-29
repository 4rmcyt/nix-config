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
        plugins = ["github.com/caddy-dns/cloudflare@v0.0.0-20250210163627-a2b97caf94f3"];
        hash = "sha256-STs4RGMQCAHBi+5bQN2R94RhOMzAYqBa8GF5l2BZMXE=";
      };

      globalConfig = ''
        email ${email}
      '';

      virtualHosts."dify.${domain}".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_DNS_API_TOKEN}
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
