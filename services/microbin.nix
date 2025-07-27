{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.microbin = {
    enable = true;
    settings = {
      MICROBIN_BIND = "127.0.0.1";
      MICROBIN_PORT = "8084";
      MICROBIN_PUBLIC_PATH = "https://paste.example.com";
      MICROBIN_EDITABLE = true;
      MICROBIN_HIGHLIGHTSYNTAX = true;
      MICROBIN_GC_DAYS = 30;
      MICROBIN_TITLE = "Homeserver Pastebin";
      MICROBIN_SHORT_PATH = "https://p.in";
      MICROBIN_QR = true;
      MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
      MICROBIN_ENCRYPTION_SERVER_SIDE = true;
      MICROBIN_BASIC_AUTH_USERNAME = "microbin";
      MICROBIN_BASIC_AUTH_PASSWORD = config.sops.secrets.microbin_user_password.path;
      MICROBIN_ADMIN_USERNAME = "admin";
      MICROBIN_ADMIN_PASSWORD = config.sops.secrets.microbin_admin_password.path;
    };
  };

}
