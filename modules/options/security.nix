{ lib, ... }:
{
  options.my.security.ssl = {
    certPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the system's default SSL certificate.";
    };
    keyPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the system's default SSL private key.";
    };
  };
}
