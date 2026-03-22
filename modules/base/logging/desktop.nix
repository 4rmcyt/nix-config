_: {
  # Desktop journald overrides — more storage and longer retention than base defaults
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    SystemMaxFileSize=100M
    MaxRetentionSec=1month
  '';
}
