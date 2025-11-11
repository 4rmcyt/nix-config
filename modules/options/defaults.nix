{
  config,
  lib,
  ...
}: let
  secretsFile = ../../secrets/common.yaml;
in {
  # =================================================================
  # 1. SOPS Secrets
  # =================================================================
  sops.secrets = {
    defaults_user = {
      sopsFile = secretsFile;
      key = "user";
    };
    defaults_email = {
      sopsFile = secretsFile;
      key = "email";
    };
    defaults_git_username = {
      sopsFile = secretsFile;
      key = "git_username";
    };
    defaults_git_signing_key = {
      sopsFile = secretsFile;
      key = "git_signing_key";
    };
    defaults_domain = {
      sopsFile = secretsFile;
      key = "domain";
    };
    defaults_timezone = {
      sopsFile = secretsFile;
      key = "timezone";
    };
    defaults_locale = {
      sopsFile = secretsFile;
      key = "locale";
    };
    defaults_gateway = {
      sopsFile = secretsFile;
      key = "gateway";
    };
    defaults_homeserver_lan = {
      sopsFile = secretsFile;
      key = "homeserver_lan";
    };
    defaults_desktop_lan = {
      sopsFile = secretsFile;
      key = "desktop_lan";
    };
    defaults_desktop_wifi = {
      sopsFile = secretsFile;
      key = "desktop_wifi";
    };
    defaults_matebook_wifi = {
      sopsFile = secretsFile;
      key = "matebook_wifi";
    };
  };

  # =================================================================
  # 2. Config Values (loaded from secrets)
  # =================================================================
  config = {
    my.defaults = {
      user = lib.mkDefault config.sops.secrets.user.path;
      email = lib.mkDefault config.sops.secrets.email.path;
      gitUsername = lib.mkDefault config.sops.secrets.git_username.path;
      gitSigningKey = lib.mkDefault config.sops.secrets.git_signing_key.path;
      domain = lib.mkDefault config.sops.secrets.domain.path;
      timezone = lib.mkDefault config.sops.secrets.timezone.path;
      locale = lib.mkDefault config.sops.secrets.locale.path;
      gateway = lib.mkDefault config.sops.secrets.gateway.path;
      homeserver_lan = lib.mkDefault config.sops.secrets.homeserver_lan.path;
      desktop_lan = lib.mkDefault config.sops.secrets.desktop_lan.path;
      desktop_wifi = lib.mkDefault config.sops.secrets.desktop_wifi.path;
      matebook_wifi = lib.mkDefault config.sops.secrets.matebook_wifi.path;
    };
  };

  options.my.defaults = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Primary username for the system";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Primary email address";
    };

    gitUsername = lib.mkOption {
      type = lib.types.str;
      description = "Git username";
    };

    gitSigningKey = lib.mkOption {
      type = lib.types.str;
      description = "GPG key ID for git commit signing";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Primary domain for homeserver services";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      description = "System timezone";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      description = "System locale";
    };

    gateway = lib.mkOption {
      type = lib.types.str;
      description = "Default gateway IP address";
    };

    homeserver_lan = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address of the homeserver";
    };

    desktop_lan = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address of the desktop LAN connection";
    };

    desktop_wifi = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address of the desktop WiFi connection";
    };

    matebook_wifi = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address of the Matebook WiFi connection";
    };
  };
}
