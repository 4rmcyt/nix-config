{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.microbin = {
    enable = true;
    listenAddr = "0.0.0.0";
    port = 8084;

    settings = {
      admin_username = "admin";
      private = true;
      no_listing = true;
    };

    systemd.services.microbin.serviceConfig = {
      EnvironmentFile = config.sops.secrets.microbin_secrets.path;
    };
  };
}
