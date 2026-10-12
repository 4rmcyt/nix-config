{config, ...}: {
  sops.secrets.ntfy_env = {
    sopsFile = ../../../secrets/ntfy.yaml;
  };

  services.ntfy-sh = {
    enable = true;
    environmentFile = config.sops.secrets.ntfy_env.path;
    settings = {
      base-url = "https://ntfy.${config.my.defaults.domain}";
      listen-http = "127.0.0.1:${toString config.my.network.ports.ntfy}";
      auth-default-access = "deny-all";
      behind-proxy = true;
      # Caddy appends its loopback peer to X-Forwarded-For; drop it so the real client is right-most.
      proxy-trusted-hosts = "127.0.0.1/32,::1/128";
      # CrowdSec's ntfy parser reads JSON; 401/403 are debug-level upstream, so lift only those.
      log-format = "json";
      log-level-overrides = [
        "error_code=40101 -> debug"
        "error_code=40301 -> debug"
      ];
    };
  };

  my.crowdsec.ntfy.enable = true;
}
