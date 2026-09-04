_: {
  # Structured journald options for better readability and error-checking.
  services.journald = {
    settings.Journal = {
      Storage = "persistent";
      SystemMaxUse = "500M";
      SystemMaxFileSize = "50M";
      SystemMaxFiles = 10;
      MaxRetentionSec = "30day";
      ForwardToSyslog = false;
      ForwardToWall = true;
      MaxLevelWall = "crit";
      RateLimitIntervalSec = "30s";
      RateLimitBurst = 10000;
      Compress = true;
      LineMax = 65536;
    };
  };
}
