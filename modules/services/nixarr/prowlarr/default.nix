# modules/services/nixarr/prowlarr/default.nix
{
  config,
  lib,
  ...
}: {
  imports = [
    # prowlarr_db_password is mode 0440 owner=postgres group=prowlarr.
    ((import ../lib/pg-env.nix {inherit lib;}) {
      name = "prowlarr";
      envLines = [
        "PROWLARR__POSTGRES__HOST=127.0.0.1"
        "PROWLARR__POSTGRES__PORT=5432"
        "PROWLARR__POSTGRES__USER=prowlarr"
        "PROWLARR__POSTGRES__MAINDB=prowlarr"
        "PROWLARR__POSTGRES__LOGDB=prowlarr-log"
        "PROWLARR__POSTGRES__PASSWORD=%s"
      ];
      passwordSecretPath = config.sops.secrets.prowlarr_db_password.path;
    })
  ];

  # Prowlarr reads PROWLARR__POSTGRES__* env vars natively (same mechanism as
  # every other Servarr app) -- no need to hand-edit config.xml via xmlstarlet.
  services.prowlarr = {
    enable = true;
    dataDir = "/data/media/.state/nixarr/prowlarr";
    settings.server.port = config.my.network.ports.prowlarr;
  };

  systemd.services.prowlarr = {
    after = ["data.mount" "prowlarr-pg-env.service"];
    requires = ["data.mount" "prowlarr-pg-env.service"];
    serviceConfig.EnvironmentFile = "/run/prowlarr-secrets/pg-env";
  };
}
