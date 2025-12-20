{lib, ...}: let
  secretsFile = ../../secrets/common.yaml;
  secretsData = {
    user = "zeev";
    email = "redacted@example.com";
    git_username = "4rmcyt";
    git_signing_key = "D85B52C9288A138E";
    domain = "example.com";
    timezone = "America/Edmonton";
    locale = "en_US.UTF-8";
    gateway = "192.168.1.254";
    homeserver_lan = "192.168.1.165";
    desktop_lan = "192.168.1.118";
    desktop_wifi = "192.168.1.239";
    matebook_wifi = "192.168.1.132";
  };
in {
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

  config = {
    my.defaults = {
      user = lib.mkDefault secretsData.user;
      email = lib.mkDefault secretsData.email;
      gitUsername = lib.mkDefault secretsData.git_username;
      gitSigningKey = lib.mkDefault secretsData.git_signing_key;
      domain = lib.mkDefault secretsData.domain;
      timezone = lib.mkDefault secretsData.timezone;
      locale = lib.mkDefault secretsData.locale;
      gateway = lib.mkDefault secretsData.gateway;
      homeserver_lan = lib.mkDefault secretsData.homeserver_lan;
      desktop_lan = lib.mkDefault secretsData.desktop_lan;
      desktop_wifi = lib.mkDefault secretsData.desktop_wifi;
      matebook_wifi = lib.mkDefault secretsData.matebook_wifi;
    };

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
