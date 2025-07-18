{ config, pkgs, lib, ... }:

{
  services.paperless = {
    enable = true;
    # This is the correct, idiomatic way to provide the admin password.
    # It now points to your new 'paperless_secrets' sops group.
    passwordFile = config.sops.secrets.paperless_secrets.path;
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      # The password is now handled by `passwordFile` above, so this line is removed.
      PAPERLESS_URL = "https://paperless.example.com";
      PAPERLESS_TIME_ZONE = "America/Edmonton";
      # Ensure Paperless uses the dedicated redis instance
      PAPERLESS_REDIS = "redis://localhost:6379/1";
    };
  };

  # Enable a dedicated redis instance for paperless
  services.redis.servers.paperless = {
    enable = true;
    port = 6379;
    # Using a different database number isolates it from other services
    database = 1;
  };
}
