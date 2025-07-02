{ config, pkgs, ... }:

{
  sops.secrets.paperless_admin_password = { };

  services.paperless = {
    enable = true;
    port = 8082;
    address = "127.0.0.1";
    
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_ADMIN_PASSWORD = "$(cat ${config.sops.secrets.paperless_admin_password.path})";
      PAPERLESS_URL = "https://paperless.yourdomain.com";
      PAPERLESS_ALLOWED_HOSTS = "paperless.yourdomain.com,localhost,127.0.0.1";
      PAPERLESS_CORS_ALLOWED_HOSTS = "https://paperless.yourdomain.com";
      PAPERLESS_USE_X_FORWARD_HOST = true;
      PAPERLESS_USE_X_FORWARD_PORT = true;
      PAPERLESS_USE_X_FORWARD_PROTO = true;
      
      # OCR settings
      PAPERLESS_OCR_LANGUAGE = "eng+heb";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };
  };

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8082 ];
}