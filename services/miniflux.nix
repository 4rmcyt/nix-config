# { config, pkgs, ... }:

# let

#   minifluxCredentials = pkgs.writeText "miniflux-credentials" ''
#     admin:$(cat ${config.sops.secrets.miniflux_admin_password.path})
#   '';
# in
# {
#   sops.secrets.miniflux_admin_password = {};

#   services.miniflux = {
#     enable = true;
#     CREATE_ADMIN = 1;
#     adminCredentialsFile = minifluxCredentials;
#     config = {
#       LISTEN_ADDR = "127.0.0.1:8086";
#     };
#   };
# }

{
  config,
  lib,
  pkgs,
  ...
}:
let
  service = "miniflux";
  hl = config.homelab;
  cfg = hl.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "news.${hl.baseDomain}";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Miniflux";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "Minimalist and opinionated feed reader";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "miniflux.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Services";
    };
    adminCredentialsFile = lib.mkOption {
      description = "File with admin credentials";
      type = lib.types.path;
    };
  };
  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
      adminCredentialsFile = cfg.adminCredentialsFile;
      config = {
        BASE_URL = "https://miniflux.example.com";
        CREATE_ADMIN = "1";
        LISTEN_ADDR = "127.0.0.1:8086";
        OAUTH2_PROVIDER = "oidc";
        OAUTH2_CLIENT_ID = "miniflux";
        OAUTH2_REDIRECT_URL = "https://miniflux.example.com/oauth2/oidc/callback";
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://keycloak.example.com/realms/master";
        OAUTH2_USER_CREATION = "1";
        DISABLE_LOCAL_AUTH = "true";
      };
    };
  };
}