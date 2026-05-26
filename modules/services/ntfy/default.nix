{config, ...}: {
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.${config.my.defaults.domain}";
      listen-http = "127.0.0.1:9991";
      auth-default-access = "deny-all";
      behind-proxy = true;
    };
  };
}
