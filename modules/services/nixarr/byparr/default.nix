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
      # Image's own HEALTHCHECK CMD (curl /health) runs every 15m by default --
      # too slow for camoufox's browser-context crashes (upstream #294), where
      # the process stays up but serves 500/408 for minutes. Tighten the cadence
      # and have podman restart on failure instead of just reporting unhealthy.
      "--health-interval=1m"
      "--health-timeout=30s"
      "--health-retries=2"
      "--health-on-failure=restart"
    ];
    environment = {
      PORT = "8191";
      TZ = config.my.defaults.timezone;
    };
  };

  # Podman's default on-failure exit still applies when the health check
  # itself can't run (e.g. browser process gone) -- restart promptly rather
  # than waiting on systemd's default backoff.
  systemd.services.podman-byparr.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "2s";
  };

  networking.firewall.allowedTCPPorts = [
    8191 # Byparr (FlareSolverr-compatible Cloudflare bypass)
  ];
}
