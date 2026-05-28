{config, ...}: let
  inherit (config.my.defaults) domain;
in {
  sops.secrets.headscale_private_key = {
    sopsFile = ../../../secrets/headscale.yaml;
    owner = "headscale";
    group = "headscale";
    mode = "0400";
  };

  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 8080;

    settings = {
      server_url = "https://hs.${domain}";

      private_key_path = config.sops.secrets.headscale_private_key.path;

      log = {
        level = "info";
        format = "text";
      };

      logtail.enabled = false;

      database = {
        type = "sqlite";
        sqlite.path = "/var/lib/headscale/db.sqlite";
      };

      dns = {
        magic_dns = true;
        base_domain = "ts.${domain}";
        nameservers.global = ["1.1.1.1" "1.0.0.1"];
        search_domains = [];
      };

      # Embedded DERP — gcp Cloud is a good relay location
      derp = {
        server = {
          enabled = true;
          region_id = 901;
          region_code = "us-central1-a";
          region_name = "GCP US Central 1 (Iowa, Zone A)";
          stun_listen_addr = "0.0.0.0:3478";
        };
        auto_update_enabled = false;
        update_frequency = "24h";
      };

      # Disable metrics endpoint exposure (scraped internally by prometheus)
      metrics_listen_addr = "127.0.0.1:9091";
    };
  };
}
