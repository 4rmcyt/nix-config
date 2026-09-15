{config, ...}: {
  virtualisation.oci-containers.containers.byparr = {
    autoStart = true;
    image = "ghcr.io/thephaseless/byparr:latest";
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      # Camoufox/Firefox needs more than podman's 64m default shm, or it
      # crashes mid-challenge-solve (upstream: ThePhaseless/Byparr#283)
      "--shm-size=1gb"
      "--security-opt=no-new-privileges"
      # Dockerfile ends on USER 1000, no root-only chown/setuid dance and no
      # device passthrough -- unprivileged process, safe to drop everything.
      "--cap-drop=all"
    ];
    environment = {
      PORT = "8191";
      TZ = config.my.defaults.timezone;
    };
  };

  networking.firewall.allowedTCPPorts = [
    8191 # Byparr (FlareSolverr-compatible Cloudflare bypass)
  ];
}
