{config, ...}: let
  inherit (config.my.defaults) domain;
in {
  sops.secrets.headplane_cookie_secret = {
    sopsFile = ../../../secrets/headplane.yaml;
    owner = config.services.headscale.user;
    group = config.services.headscale.group;
    mode = "0400";
  };

  services.headplane = {
    enable = true;

    settings = {
      server = {
        host = "127.0.0.1";
        port = 3000;
        base_url = "https://hs.${domain}";
        cookie_secret_path = config.sops.secrets.headplane_cookie_secret.path;
        cookie_secure = true;
        data_path = "/var/lib/headplane";
      };

      headscale = {
        url = "http://127.0.0.1:8080";
        public_url = "https://hs.${domain}";
        config_path = "/etc/headscale/config.yaml";
        config_strict = false;
      };

      integration = {
        proc.enabled = true;
        agent.enabled = false;
      };
    };
  };
}
