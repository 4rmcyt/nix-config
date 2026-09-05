{config, ...}: let
  commonEnv = {
    TZ = config.my.defaults.timezone;
    DISPATCHARR_ENV = "modular";
    DISPATCHARR_PORT = toString config.my.network.ports.dispatcharr;
    # Traefik proxies over the tailnet; dispatcharr's setup-wizard "local
    # network" check only recognizes RFC1918 + loopback, not Tailscale's
    # CGNAT range (100.64.0.0/10), so the initial admin setup page refuses
    # the connection unless the tailnet peer IP is allowlisted explicitly.
    DISPATCHARR_SETUP_ALLOWED_IP = config.my.network.hosts.desktop_ts;
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

  # Both containers connect to Postgres/Redis over host.containers.internal
  # at startup — without this ordering they can race postgresql/redis on a
  # cold boot and fail to connect.
  systemd.services.podman-dispatcharr.after = ["postgresql.service" "redis-homeserver.service"];
  systemd.services.podman-dispatcharr.requires = ["postgresql.service" "redis-homeserver.service"];
  systemd.services.podman-dispatcharr-celery.after = ["postgresql.service" "redis-homeserver.service"];
  systemd.services.podman-dispatcharr-celery.requires = ["postgresql.service" "redis-homeserver.service"];

  virtualisation.oci-containers.containers = {
    dispatcharr = {
      autoStart = true;
      image = "ghcr.io/dispatcharr/dispatcharr:latest";
      environment = commonEnv;
      environmentFiles = envFile;
      volumes = ["/var/lib/dispatcharr:/data"];
      ports = ["127.0.0.1:${toString config.my.network.ports.dispatcharr}:${toString config.my.network.ports.dispatcharr}"];
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
