{config, ...}: {
  virtualisation.oci-containers.containers.stremio = {
    autoStart = true;
    image = "docker.io/tsaridas/stremio-docker:latest";
    environment = {
      TZ = config.my.defaults.timezone;
      # Renamed off the image's 8080 default: collides on the host with
      # traefik-metrics (--network=host, no NAT to absorb it).
      WEBUI_INTERNAL_PORT = toString config.my.network.ports.stremio;
      # Derives the streaming server URL from the browser's request origin, avoiding a
      # separate SERVER_URL/IPADDRESS HTTPS dance since Traefik already terminates TLS.
      AUTO_SERVER_URL = "1";
      CASTING_DISABLED = "1";
    };
    volumes = ["/var/lib/stremio-server:/root/.stremio-server"];
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--security-opt=no-new-privileges"
      # NOT actually safe to drop everything: entrypoint creates/opens nginx tmp/log
      # files before dropping to its own user, needing DAC_OVERRIDE/CHOWN or it crash-loops.
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
