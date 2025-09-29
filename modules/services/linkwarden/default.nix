{
  config,
  lib,
  ...
}:
let
  service = "linkwarden";
  cfg = config.homelab.services.${service};
  inherit (config) homelab;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    stateDir = lib.mkOption {
      type = lib.types.path;
      description = "Directory containing the persistent state data to back up";
      default = "/var/lib/linkwarden";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "${service}.${homelab.baseDomain}";
    };
    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };
    listenPort = lib.mkOption {
      type = lib.types.int;
      default = 3010;
    };
    secretEnvironmentFile = lib.mkOption {
      description = "File with secret environment variables, e.g. NEXTAUTH_SECRET and POSTGRES_PASSWORD";
      type = with lib.types; nullOr path;
      default = config.age.secrets.linkwardenEnv.path;
      example = lib.literalExpression ''
        pkgs.writeText "linkwarden-secret-environment" '''
          NEXTAUTH_SECRET=<secret>
          POSTGRES_PASSWORD=<pass>
        '''
      '';
    };

    enableRegistration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow user registration in Linkwarden";
    };
  };
  config = lib.mkIf cfg.enable {
    services.linkwarden = {
      enable = true;
      host = cfg.listenAddress;
      port = cfg.listenPort;
      database.port = cfg.database.port;
      storageLocation = cfg.stateDir;
      inherit (cfg) enableRegistration;
      # environment = { };
      # https://docs.linkwarden.app/self-hosting/environment-variables
      environmentFile = lib.mkIf (cfg.secretEnvironmentFile != null) cfg.secretEnvironmentFile;
      # Path to a file containing environment variables, for example for NEXTAUTH_SECRET=<secret>,   POSTGRES_PASSWORD=<pass>
    };
  };
}
