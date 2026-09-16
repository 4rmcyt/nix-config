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
      # Tried tightening the image's own HEALTHCHECK (curl /health, 15m
      # interval) to catch hung challenge-solves faster, with
      # --health-on-failure=restart. Reverted: /health launches a real
      # browser and routinely takes >30s, so a 1m/30s/2-retry cadence just
      # health-fails and restarts the container every ~100s, killing
      # in-flight solves -- worse than the problem it was meant to fix.
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
