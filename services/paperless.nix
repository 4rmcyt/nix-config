{ config, pkgs, lib, ... }:

{
  services.paperless = {
    enable = true;
    passwordFile = config.sops.secrets.paperless.path;
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_URL = "https://paperless.labhome.work";
      PAPERLESS_TIME_ZONE = "America/Edmonton";

      PAPERLESS_OCR_LANGUAGE = "eng+heb";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };
  };

  # Enable a dedicated redis instance for paperle
}