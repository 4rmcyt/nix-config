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
      DATABASE_URL=postgresql://comet:${config.sops.placeholder.comet_db_password}@host.containers.internal:5432/comet
      FASTAPI_PORT=${toString config.my.network.ports.comet}
      SCRAPE_PROWLARR=True
      PROWLARR_URL=http://host.containers.internal:${toString config.my.network.ports.prowlarr}
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
    environmentFiles = [config.sops.templates."comet.env".path];
    volumes = ["/var/lib/comet:/app/data"];
    # Bound on both loopback (Traefik, on the host) and the podman bridge
    # gateway (other containers reaching it via host.containers.internal,
    # e.g. AIOStreams fetching its manifest) -- 127.0.0.1 alone is
    # unreachable from inside another container's network namespace.
    ports = [
      "127.0.0.1:${toString config.my.network.ports.comet}:${toString config.my.network.ports.comet}"
      "${config.my.network.podmanGateway}:${toString config.my.network.ports.comet}:${toString config.my.network.ports.comet}"
    ];
    extraOptions = [
      "--add-host=host.containers.internal:host-gateway"
      "--label=io.containers.autoupdate=registry"
      "--security-opt=no-new-privileges"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/comet 0750 root root -"
  ];
}
