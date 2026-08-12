{config, ...}: let
  commonEnv = {
    TZ = config.my.defaults.timezone;
    DISPATCHARR_ENV = "modular";
    DISPATCHARR_PORT = "9191";
  };
  commonExtraOptions = [
    "--add-host=host.containers.internal:host-gateway"
    "--label=io.containers.autoupdate=registry"
    "--device=/dev/dri:/dev/dri"
  ];
  envFile = [config.sops.templates."dispatcharr.env".path];
in {
  sops.templates."dispatcharr.env" = {
    owner = "root";
    mode = "0400";
    content = ''
      POSTGRES_HOST=host.containers.internal
      POSTGRES_PORT=5432
      POSTGRES_DB=dispatcharr
      POSTGRES_USER=dispatcharr
      POSTGRES_PASSWORD=${config.sops.placeholder.dispatcharr_db_password}
      REDIS_HOST=host.containers.internal
      REDIS_PORT=6379
      REDIS_DB=3
      REDIS_PASSWORD=${config.sops.placeholder.redis-oauth2-proxy-password}
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/dispatcharr 0755 root root -"
  ];

  virtualisation.oci-containers.containers = {
    dispatcharr = {
      autoStart = true;
      image = "ghcr.io/dispatcharr/dispatcharr:latest";
      environment = commonEnv;
      environmentFiles = envFile;
      volumes = ["/var/lib/dispatcharr:/data"];
      ports = ["127.0.0.1:9191:9191"];
      extraOptions = commonExtraOptions;
    };

    dispatcharr-celery = {
      autoStart = true;
      image = "ghcr.io/dispatcharr/dispatcharr:latest";
      environment =
        commonEnv
        // {
          DJANGO_SETTINGS_MODULE = "dispatcharr.settings";
          PYTHONUNBUFFERED = "1";
        };
      environmentFiles = envFile;
      volumes = ["/var/lib/dispatcharr:/data"];
      extraOptions = commonExtraOptions ++ ["--entrypoint=/app/docker/entrypoint.celery.sh"];
    };
  };
}
