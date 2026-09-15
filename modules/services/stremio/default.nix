{config, ...}: {
  virtualisation.oci-containers.containers.stremio = {
    autoStart = true;
    image = "docker.io/tsaridas/stremio-docker:latest";
    environment = {
      TZ = config.my.defaults.timezone;
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
      # NOT actually safe to drop everything: confirmed live (2026-09-15) --
      # entrypoint creates /var/lib/nginx/tmp/client_body and opens
      # /var/lib/nginx/logs/error.log before dropping to its own user, which
      # needs DAC_OVERRIDE/CHOWN or it's "Permission denied (13)" and the
      # container crash-loops. Same LSIO-style baseline as kapowarr/seerr.
      "--cap-drop=all"
      "--cap-add=CHOWN"
      "--cap-add=DAC_OVERRIDE"
      "--cap-add=FOWNER"
      "--cap-add=KILL"
      "--cap-add=SETGID"
      "--cap-add=SETUID"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/stremio-server 0750 root root -"
  ];
}
