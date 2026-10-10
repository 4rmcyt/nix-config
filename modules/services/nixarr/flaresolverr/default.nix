{config, ...}: {
  # Not for Prowlarr logins: its request.post triggers RuTracker's login captcha (RuTracker uses byparr).
  services.flaresolverr = {
    enable = true;
    port = config.my.network.ports.flaresolverr;
  };

  systemd.services.flaresolverr.environment = {
    HOST = "127.0.0.1";
    TZ = config.my.defaults.timezone;
    # INFO logs request bodies, incl. RuTracker login_password.
    LOG_LEVEL = "warning";
  };
}
