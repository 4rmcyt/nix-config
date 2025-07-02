# /etc/nixos/services/paperless.nix
{ config, pkgs,... }:

{
  sops.secrets.paperless_admin_password = { };

  services.postgresql.ensureDatabases = [ "paperless" ];
  # FIX: Complete the ensureUsers definition
  services.postgresql.ensureUsers = [
    {
      name = "paperless";
      ensureDBOwnership = true;
    }
  ];

  services.paperless = {
    enable = true;
    address = "127.0.0.1";
    port = 8082;
    passwordFile = config.sops.secrets.paperless_admin_password.path;
    settings = {
      PAPERLESS_URL = "https://paperless.example.com";
      PAPERLESS_OCR_LANGUAGE = "eng";
      PAPERLESS_TIME_ZONE = "America/Edmonton";
      PAPERLESS_DBHOST = "/run/postgresql";
      PAPERLESS_DBNAME = "paperless";
      PAPERLESS_DBUSER = "paperless";
    };
  };
}