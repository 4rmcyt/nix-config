{
  config,
  lib,
  ...
}: {
  services.headplane = {
    enable = true;
    settings = {
      server = {
        host = "127.0.0.1";
        port = 3004;
        base_url = "https://hp.${config.my.defaults.domain}";
        cookie_secret_path = config.sops.secrets.headplane_cookie_secret.path;
        cookie_secure = true;
        data_path = "/var/lib/headplane";
      };
      headscale = {
        url = "http://127.0.0.1:${toString config.services.headscale.port}";
        config_strict = false;
      };
      integration = {
        proc.enabled = false;
        agent.enabled = false;
      };
    };
  };

  # headscale runs locally — headplane starts after it
  systemd.services.headplane = {
    after = lib.mkForce ["sops-nix.service" "headscale.service"];
    requires = lib.mkForce ["headscale.service"];
  };

  sops.secrets.headplane_cookie_secret = {
    sopsFile = ../../../secrets/headplane.yaml;
    owner = "headscale";
    group = "headscale";
    mode = "0400";
  };
}
