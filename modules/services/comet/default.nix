{config, ...}: {
  sops.secrets.prowlarr_api_key = {
    sopsFile = ../../../secrets/medialib.yaml;
    key = "prowlarr_api_key";
    owner = "root";
    mode = "0400";
  };

  sops.templates."comet.env" = {
    owner = "root";
    mode = "0400";
    content = ''
      DATABASE_URL=postgresql://comet:${config.sops.placeholder.comet_db_password}@127.0.0.1:5432/comet
      FASTAPI_PORT=${toString config.my.network.ports.comet}
      SCRAPE_PROWLARR=True
      PROWLARR_URL=http://127.0.0.1:${toString config.my.network.ports.prowlarr}
      PROWLARR_API_KEY=${config.sops.placeholder.prowlarr_api_key}
    '';
  };

  systemd.services.podman-comet = {
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
  };

  virtualisation.oci-containers.containers.comet = {
    autoStart = true;
    image = "ghcr.io/g0ldyy/comet:latest";
    environment = {
      TZ = config.my.defaults.timezone;
    };
    environmentFiles = [config.sops.templates."comet.env".path];
    volumes = ["/var/lib/comet:/app/data"];
    # Host networking instead of the podman bridge: Comet and AIOStreams both need to
    # reach each other and Postgres on localhost with no extra port publishing.
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--security-opt=no-new-privileges"
      "--cap-drop=all"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/comet 0750 root root -"
  ];
}
