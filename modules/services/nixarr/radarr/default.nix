# modules/services/nixarr/radarr/default.nix
{
  config,
  lib,
  ...
}: {
  # Radarr reads RADARR__POSTGRES__* env vars natively -- no need to
  # hand-edit config.xml via xmlstarlet.
  systemd.services.radarr-pg-env = {
    description = "Write Radarr PostgreSQL environment file";
    after = [
      "postgresql.service"
      "postgresql-setup-users.service"
    ];
    requires = ["postgresql.service"];
    wantedBy = ["radarr.service"];
    before = ["radarr.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "radarr-secrets";
      RuntimeDirectoryMode = "0750";
      User = "radarr";
      Group = "radarr";
    };
    script = ''
      printf 'RADARR__POSTGRES__HOST=127.0.0.1\nRADARR__POSTGRES__PORT=5432\nRADARR__POSTGRES__USER=radarr\nRADARR__POSTGRES__MAINDB=radarr\nRADARR__POSTGRES__LOGDB=radarr-log\nRADARR__POSTGRES__PASSWORD=%s\n' \
        "$(cat ${config.sops.secrets.radarr_db_password.path} | tr -d '\n\r')" \
        > /run/radarr-secrets/pg-env
      chmod 600 /run/radarr-secrets/pg-env
    '';
  };

  services.radarr = {
    enable = true;
    user = "radarr";
    group = "radarr";
    dataDir = "/data/media/.state/nixarr/radarr";
    settings.server.port = 7878;
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
