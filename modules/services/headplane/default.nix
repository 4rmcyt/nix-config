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
        url = "https://hs.${config.my.defaults.domain}";
        config_strict = false;
      };
      integration = {
        proc.enabled = false;
        agent.enabled = false;
      };
    };
  };

  # headplane runs under headscale user (upstream module hardcodes this)
  # headscale itself is disabled on this host — create the user manually
  users.users.headscale = {
    isSystemUser = true;
    group = "headscale";
  };
  users.groups.headscale = {};

  # headscale runs on GCP — start headplane without waiting for local headscale
  systemd.services.headplane = {
    after = lib.mkForce ["sops-nix.service"];
    requires = lib.mkForce [];
    wants = lib.mkForce [];
  };

  sops.secrets.headplane_cookie_secret = {
    sopsFile = ../../../secrets/headplane.yaml;
    owner = "headscale";
    group = "headscale";
    mode = "0400";
  };
}
