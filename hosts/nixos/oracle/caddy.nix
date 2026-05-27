{
  config,
  pkgs,
  ...
}: let
  inherit (config.my.defaults) domain email;
in {
  # Cloudflare API token for DNS-01 ACME challenge.
  # File format: CLOUDFLARE_API_TOKEN=<token>
  sops.secrets.cloudflare_api_token_oracle = {
    sopsFile = ../../../secrets/oracle.yaml;
    owner = "caddy";
    group = "caddy";
    mode = "0400";
  };

  services.caddy = {
    enable = true;

    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
      hash = "sha256-VHm9POg2KixGsMsAcfFFDMK9x6niRJ1iJV9kkSwkSjc=";
    };

    globalConfig = ''
      email ${email}
    '';

    # https://hs.example.com
    #   /web*      → headplane :3000
    #   everything → headscale  :8080
    #
    # Caddy is used instead of Traefik because Traefik does not support
    # the Tailscale control protocol's non-standard Upgrade header.
    virtualHosts."hs.${domain}" = {
      extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
          resolvers 1.1.1.1
        }

        @headplane path /web* /static* /assets*
        reverse_proxy @headplane 127.0.0.1:3000

        reverse_proxy 127.0.0.1:8080
      '';
    };
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile =
    config.sops.secrets.cloudflare_api_token_oracle.path;
}
