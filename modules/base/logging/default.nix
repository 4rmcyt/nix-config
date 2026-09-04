{lib, ...}: {
  # Structured journald options for better readability and error-checking.
  # mkDefault so host-specific overrides (homeserver, gcp-relay, router) win.
  services.journald.settings.Journal = {
    Storage = lib.mkDefault "persistent";
    SystemMaxUse = lib.mkDefault "500M";
    SystemMaxFileSize = lib.mkDefault "50M";
    SystemMaxFiles = lib.mkDefault 10;
    MaxRetentionSec = lib.mkDefault "30day";
    ForwardToSyslog = lib.mkDefault false;
    ForwardToWall = lib.mkDefault true;
    MaxLevelWall = lib.mkDefault "crit";
    RateLimitIntervalSec = lib.mkDefault "30s";
    RateLimitBurst = lib.mkDefault 10000;
    Compress = lib.mkDefault true;
    LineMax = lib.mkDefault 65536;
  };
}
