{config, ...}: {
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

  virtualisation.oci-containers.containers.dispatcharr = {
    autoStart = true;
    image = "ghcr.io/dispatcharr/dispatcharr:latest";
    environment = {
      TZ = config.my.defaults.timezone;
      DISPATCHARR_ENV = "aio";
    };
    environmentFiles = [config.sops.templates."dispatcharr.env".path];
    volumes = [
      "/var/lib/dispatcharr:/data"
    ];
    ports = ["127.0.0.1:9191:9191"];
    extraOptions = ["--add-host=host.containers.internal:host-gateway"];
  };
}
