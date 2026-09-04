# modules/services/nixarr/radarr/default.nix
{
  config,
  lib,
  ...
}: {
  imports = [
    ((import ../lib/pg-env.nix {inherit lib;}) {
      name = "radarr";
      envLines = [
        "RADARR__POSTGRES__HOST=127.0.0.1"
        "RADARR__POSTGRES__PORT=5432"
        "RADARR__POSTGRES__USER=radarr"
        "RADARR__POSTGRES__MAINDB=radarr"
        "RADARR__POSTGRES__LOGDB=radarr-log"
        "RADARR__POSTGRES__PASSWORD=%s"
      ];
      passwordSecretPath = config.sops.secrets.radarr_db_password.path;
    })
  ];

  # Radarr reads RADARR__POSTGRES__* env vars natively -- no need to
  # hand-edit config.xml via xmlstarlet.
  services.radarr = {
    enable = true;
    user = "radarr";
    group = "radarr";
    dataDir = "/data/media/.state/nixarr/radarr";
    settings.server.port = config.my.network.ports.radarr;
  };

  systemd.services.radarr = {
    after = ["data.mount" "radarr-pg-env.service"];
    requires = ["data.mount" "radarr-pg-env.service"];
    serviceConfig = {
      EnvironmentFile = "/run/radarr-secrets/pg-env";
      # nixpkgs' module hardcodes 0022; we need group-writable output to
      # match the rest of the media stack's shared "media" group access.
      UMask = lib.mkForce "0002";
    };
  };
}
