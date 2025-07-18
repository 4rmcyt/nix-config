{ config, pkgs, lib, ... }:

{
  services.paperless = {
    enable = true;
    passwordFile = config.sops.secrets.paperless.path;
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_URL = "https://paperless.example.com";
      PAPERLESS_TIME_ZONE = "America/Edmonton";
      PAPERLESS_REDIS = "redis://localhost:6379/1";

      PAPERLESS_OCR_LANGUAGE = "eng+heb";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };
  };

  # Enable a dedicated redis instance for paperle
}