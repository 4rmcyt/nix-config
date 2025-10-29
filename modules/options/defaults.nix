{lib, ...}: {
  options.my.defaults = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "zeev";
      description = "Primary username for the system";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "4rmcyt@gmail.com";
      description = "Primary email address";
    };

    gitUsername = lib.mkOption {
      type = lib.types.str;
      default = "4rmcyt";
      description = "Git username";
    };

    gitSigningKey = lib.mkOption {
      type = lib.types.str;
      default = "D85B52C9288A138E";
      description = "GPG key ID for git commit signing";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "labhome.work";
      description = "Primary domain for homeserver services";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      default = "America/Edmonton";
      description = "System timezone";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "System locale";
    };
  };

  config = {
    # Set the default values as configuration
    # Other modules can reference config.my.defaults.*
  };
}
