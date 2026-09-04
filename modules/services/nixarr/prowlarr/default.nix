# modules/services/nixarr/prowlarr/default.nix
{config, ...}: {
  # Prowlarr reads PROWLARR__POSTGRES__* env vars natively (same mechanism as
  # every other Servarr app) -- no need to hand-edit config.xml via xmlstarlet.
  systemd.services.prowlarr-pg-env = {
    description = "Write Prowlarr PostgreSQL environment file";
    after = [
      "postgresql.service"
      "postgresql-setup-users.service"
    ];
    requires = ["postgresql.service"];
    wantedBy = ["prowlarr.service"];
    before = ["prowlarr.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "prowlarr-secrets";
      RuntimeDirectoryMode = "0750";
      # prowlarr_db_password is mode 0440 owner=postgres group=prowlarr.
      User = "prowlarr";
      Group = "prowlarr";
    };
    script = ''
      printf 'PROWLARR__POSTGRES__HOST=127.0.0.1\nPROWLARR__POSTGRES__PORT=5432\nPROWLARR__POSTGRES__USER=prowlarr\nPROWLARR__POSTGRES__MAINDB=prowlarr\nPROWLARR__POSTGRES__LOGDB=prowlarr-log\nPROWLARR__POSTGRES__PASSWORD=%s\n' \
        "$(cat ${config.sops.secrets.prowlarr_db_password.path} | tr -d '\n\r')" \
        > /run/prowlarr-secrets/pg-env
      chmod 600 /run/prowlarr-secrets/pg-env
    '';
  };

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
