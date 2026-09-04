# modules/services/nixarr/sonarr/default.nix
{
  config,
  lib,
  ...
}: {
  # Sonarr reads SONARR__POSTGRES__* env vars natively -- no need to
  # hand-edit config.xml via xmlstarlet.
  systemd.services.sonarr-pg-env = {
    description = "Write Sonarr PostgreSQL environment file";
    after = [
      "postgresql.service"
      "postgresql-setup-users.service"
    ];
    requires = ["postgresql.service"];
    wantedBy = ["sonarr.service"];
    before = ["sonarr.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "sonarr-secrets";
      RuntimeDirectoryMode = "0750";
      User = "sonarr";
      Group = "sonarr";
    };
    script = ''
      printf 'SONARR__POSTGRES__HOST=127.0.0.1\nSONARR__POSTGRES__PORT=5432\nSONARR__POSTGRES__USER=sonarr\nSONARR__POSTGRES__MAINDB=sonarr\nSONARR__POSTGRES__LOGDB=sonarr-log\nSONARR__POSTGRES__PASSWORD=%s\n' \
        "$(cat ${config.sops.secrets.sonarr_db_password.path} | tr -d '\n\r')" \
        > /run/sonarr-secrets/pg-env
      chmod 600 /run/sonarr-secrets/pg-env
    '';
  };

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
