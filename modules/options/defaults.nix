{lib, config, ...}: {
  options.my.defaults = {
    user = lib.mkOption {
      type = lib.types.str;
      default = lib.removeSuffix "\n" (builtins.readFile config.sops.secrets.defaults-user.path);
      description = "Primary username for the system";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = lib.removeSuffix "\n" (builtins.readFile config.sops.secrets.defaults-email.path);
      description = "Primary email address";
    };

    gitUsername = lib.mkOption {
      type = lib.types.str;
      default = lib.removeSuffix "\n" (builtins.readFile config.sops.secrets.defaults-git_username.path);
      description = "Git username";
    };

    gitSigningKey = lib.mkOption {
      type = lib.types.str;
      default = lib.removeSuffix "\n" (builtins.readFile config.sops.secrets.defaults-git_signing_key.path);
      description = "GPG key ID for git commit signing";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = lib.removeSuffix "\n" (builtins.readFile config.sops.secrets.defaults-domain.path);
      description = "Primary domain for homeserver services";
    };

    localIp = lib.mkOption {
      type = lib.types.str;
      default = lib.removeSuffix "\n" (builtins.readFile config.sops.secrets.defaults-local_ip.path);
      description = "Local IP address of the homeserver";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      default = lib.removeSuffix "\n" (builtins.readFile config.sops.secrets.defaults-timezone.path);
      description = "System timezone";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = lib.removeSuffix "\n" (builtins.readFile config.sops.secrets.defaults-locale.path);
      description = "System locale";
    };
  };

  config = {
    sops.secrets = {
      defaults-user = {
        sopsFile = ../../secrets/common.yaml;
        key = "user";
      };
      defaults-email = {
        sopsFile = ../../secrets/common.yaml;
        key = "email";
      };
      defaults-git_username = {
        sopsFile = ../../secrets/common.yaml;
        key = "git_username";
      };
      defaults-git_signing_key = {
        sopsFile = ../../secrets/common.yaml;
        key = "git_signing_key";
      };
      defaults-domain = {
        sopsFile = ../../secrets/common.yaml;
        key = "domain";
      };
      defaults-local_ip = {
        sopsFile = ../../secrets/common.yaml;
        key = "local_ip";
      };
      defaults-timezone = {
        sopsFile = ../../secrets/common.yaml;
        key = "timezone";
      };
      defaults-locale = {
        sopsFile = ../../secrets/common.yaml;
        key = "locale";
      };
    };
  };
}
