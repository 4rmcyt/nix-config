{
  lib,
  config,
  ...
}: let
  secretsFile = ../../../secrets/common.yaml;
in {
  options.my.defaults = {
    user = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-user.path;
      description = "Primary username for the system";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-email.path;
      description = "Primary email address";
    };

    gitUsername = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-git_username.path;
      description = "Git username";
    };

    gitSigningKey = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-git_signing_key.path;
      description = "GPG key ID for git commit signing";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-domain.path;
      description = "Primary domain for homeserver services";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-timezone.path;
      description = "System timezone";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-locale.path;
      description = "System locale";
    };

    gateway = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-gateway.path;
      description = "Default gateway IP address";
    };

    homeserver_lan = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-homeserver_lan.path;
      description = "Local IP address of the homeserver";
    };

    desktop_lan = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-desktop_lan.path;
      description = "Local IP address of the desktop LAN connection";
    };

    desktop_wifi = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-desktop_wifi.path;
      description = "Local IP address of the desktop WiFi connection";
    };

    matebook_wifi = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-matebook_wifi.path;
      description = "Local IP address of the Matebook WiFi connection";
    };
  };

  config = {
    sops.secrets = builtins.listToAttrs (map (key: {
        name = "defaults-${key}";
        value = {
          sopsFile = secretsFile;
          inherit key;
          mode = "0400";
        };
      }) [
        "user"
        "email"
        "git_username"
        "git_signing_key"
        "domain"
        "timezone"
        "locale"
        "gateway"
        "homeserver_lan"
        "desktop_lan"
        "desktop_wifi"
        "matebook_wifi"
      ]);
  };
}
