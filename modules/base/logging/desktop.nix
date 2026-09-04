_: {
  services.journald.settings.Journal = {
    SystemMaxUse = "1G";
    SystemMaxFileSize = "100M";
    MaxRetentionSec = "1month";
  };
}
