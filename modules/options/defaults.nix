{lib, ...}:
  let
  secretsFile = ../../../secrets/common.yaml;
in
{
  sops.secrets = builtins.listToAttrs (map (key: {
    name = "defaults-${key}";
    value = {
      sopsFile = secretsFile;
      key = key;
      mode = "0400";
    };
  }) [
    "user"
    "email"
    "git_username"
    "git_signing_key"
    "domain"
    "local_ip"
    "timezone"
    "locale"
  ]);



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

    localIp = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.defaults-local_ip.path;
      description = "Local IP address of the homeserver";
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
  };

  config = {
    # Set the default values as configuration
    # Other modules can reference config.my.defaults.*
  };
}
