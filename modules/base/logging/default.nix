_: {
  # 1. Journald Configuration
  # Using structured options for better readability and error-checking.
  services.journald = {
    storage = "persistent";
    extraConfig = ''
      SystemMaxUse=500M
      SystemMaxFileSize=50M
      SystemMaxFiles=10
      MaxRetentionSec=30day
      ForwardToSyslog=no
      ForwardToWall=yes
      MaxLevelWall=crit
      RateLimitInterval=30s
      RateLimitBurst=10000
      Compress=yes
      LineMax=65536
    '';
  };
}
