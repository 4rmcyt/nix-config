{config, ...}: {
  sops.secrets.ntfy_env = {
    sopsFile = ../../../secrets/ntfy.yaml;
    owner = config.services.ntfy-sh.user;
  };

  services.ntfy-sh = {
    enable = true;
    environmentFile = config.sops.secrets.ntfy_env.path;
    settings = {
      base-url = "https://ntfy.${config.my.defaults.domain}";
      listen-http = "127.0.0.1:9991";
      auth-default-access = "deny-all";
      behind-proxy = true;
    };
  };
}
