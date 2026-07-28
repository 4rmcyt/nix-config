# modules/services/nixarr/bazarr/default.nix
{config, ...}: {
  systemd.services.bazarr-pg-env = {
    description = "Write Bazarr PostgreSQL environment file";
    after = [
      "postgresql.service"
      "postgresql-setup-users.service"
    ];
    requires = ["postgresql.service"];
    wantedBy = ["podman-bazarr.service"];
    before = ["podman-bazarr.service"];
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

  virtualisation.oci-containers.containers.bazarr = {
    autoStart = true;
    image = "lscr.io/linuxserver/bazarr:latest";
    environmentFiles = ["/run/bazarr-secrets/pg-env"];
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--env=PUID=${toString config.users.users.bazarr.uid}"
      "--env=PGID=${toString config.users.groups.media.gid}"
      "--env=TZ=${config.my.defaults.timezone}"
    ];
    volumes = [
      "/data/media/.state/nixarr/bazarr:/config"
      "/data/media:/data/media"
    ];
  };

  systemd.services.podman-bazarr = {
    after = ["data.mount" "bazarr-pg-env.service"];
    requires = ["data.mount" "bazarr-pg-env.service"];
  };
}
