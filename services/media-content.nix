# /etc/nixos/services/media-content.nix
{ config, pkgs,... }:

{
  # --- Audiobookshelf ---
  services.audiobookshelf = {
    enable = true;
    port = 8085;
  };

  # --- Miniflux ---
  sops.secrets.miniflux_admin_password = { };
  services.miniflux = {
    enable = true;
    createDatabaseLocally = true;
    adminCredentialsFile = config.sops.secrets.miniflux_admin_password.path;
    config = {
      BASE_URL = "https://miniflux.labhome.work";
      RUN_MIGRATIONS = "1";
      LISTEN_ADDR = "127.0.0.1:8084";
    };
  };

  # --- Microbin ---
  sops.secrets.microbin_admin_password = { };
  services.microbin = {
    enable = true;
    passwordFile = config.sops.secrets.microbin_admin_password.path;
    settings = {
      MICROBIN_PUBLIC_PATH = "https://microbin.labhome.work/";
      MICROBIN_EDITABLE = true;
      MICROBIN_PRIVATE = true;
      MICROBIN_PORT = 8083;
    };
  };
}