# modules/services/nixarr/bazarr/default.nix
{config, ...}: {
  systemd.services.bazarr-pg-env = {
    description = "Write Bazarr PostgreSQL environment file";
    after = [
      "postgresql.service"
      "postgresql-setup-users.service"
    ];
    requires = ["postgresql.service"];
    wantedBy = ["bazarr.service"];
    before = ["bazarr.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "bazarr-secrets";
      RuntimeDirectoryMode = "0750";
      User = "bazarr";
      Group = "bazarr";
    };
    script = ''
      printf 'POSTGRES_ENABLED=true\nPOSTGRES_HOST=127.0.0.1\nPOSTGRES_PORT=5432\nPOSTGRES_DATABASE=bazarr\nPOSTGRES_USERNAME=bazarr\nPOSTGRES_PASSWORD=%s\n' \
        "$(cat ${config.sops.secrets.bazarr_db_password.path} | tr -d '\n\r')" \
        > /run/bazarr-secrets/pg-env
      chmod 600 /run/bazarr-secrets/pg-env
    '';
  };

  # Bazarr reads these same POSTGRES_* env vars natively and gives them
  # precedence over config.yaml -- no container entrypoint magic needed.
  services.bazarr = {
    enable = true;
    user = "bazarr";
    group = "bazarr";
    dataDir = "/data/media/.state/nixarr/bazarr";
    listenPort = 6767;
  };

  systemd.services.bazarr = {
    after = ["data.mount" "bazarr-pg-env.service"];
    requires = ["data.mount" "bazarr-pg-env.service"];
    serviceConfig.EnvironmentFile = "/run/bazarr-secrets/pg-env";
  };
}
