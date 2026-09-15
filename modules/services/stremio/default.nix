{config, ...}: {
  virtualisation.oci-containers.containers.stremio = {
    autoStart = true;
    image = "docker.io/tsaridas/stremio-docker:latest";
    environment = {
      # Web player and streaming server both sit behind the image's own
      # nginx on one port -- Traefik only needs to proxy this single port.
      # Renamed off the image's 8080 default: that collides on the host
      # with traefik-metrics (--network=host, no NAT to absorb it).
      WEBUI_INTERNAL_PORT = toString config.my.network.ports.stremio;
      # Derives the streaming server URL from the browser's request origin
      # (Traefik forwards the Host header untouched, so this resolves to
      # stremio.<domain> without needing a separate SERVER_URL/IPADDRESS
      # HTTPS dance -- Traefik already terminates TLS for us).
      AUTO_SERVER_URL = "1";
      CASTING_DISABLED = "1";
    };
    volumes = ["/var/lib/stremio-server:/root/.stremio-server"];
    # Host networking (like byparr/comet/aiostreams) -- simplest way to
    # expose a single renamed port without extra NAT.
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--security-opt=no-new-privileges"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/stremio-server 0750 root root -"
  ];
}
