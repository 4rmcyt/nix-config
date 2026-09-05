{
  config,
  lib,
  ...
}: {
  imports = [
    ((import ../lib/pg-env.nix {inherit lib;}) {
      name = "sonarr";
      envLines = [
        "SONARR__POSTGRES__HOST=127.0.0.1"
        "SONARR__POSTGRES__PORT=5432"
        "SONARR__POSTGRES__USER=sonarr"
        "SONARR__POSTGRES__MAINDB=sonarr"
        "SONARR__POSTGRES__LOGDB=sonarr-log"
        "SONARR__POSTGRES__PASSWORD=%s"
      ];
      passwordSecretPath = config.sops.secrets.sonarr_db_password.path;
    })
  ];

  # Sonarr reads SONARR__POSTGRES__* env vars natively -- no need to
  # hand-edit config.xml via xmlstarlet.
  services.sonarr = {
    enable = true;
    user = "sonarr";
    group = "sonarr";
    dataDir = "/data/media/.state/nixarr/sonarr";
    settings.server.port = config.my.network.ports.sonarr;
  };

  systemd.services.sonarr = {
    after = ["data.mount" "sonarr-pg-env.service"];
    requires = ["data.mount" "sonarr-pg-env.service"];
    serviceConfig = {
      EnvironmentFile = "/run/sonarr-secrets/pg-env";
      # nixpkgs' module hardcodes 0022; we need group-writable output to
      # match the rest of the media stack's shared "media" group access.
      UMask = lib.mkForce "0002";
    };
  };
}
