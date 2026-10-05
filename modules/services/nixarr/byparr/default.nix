{config, ...}: {
  virtualisation.oci-containers.containers.byparr = {
    autoStart = true;
    image = "ghcr.io/thephaseless/byparr:latest";
    # Published ports are DNAT'd past the NixOS firewall: bind loopback (prowlarr) + LAN IP only.
    ports = [
      "127.0.0.1:8191:8191"
      "${config.my.network.hosts.homeserver_lan}:8191:8191"
    ];
    extraOptions = [
      "--userns=auto"
      "--label=io.containers.autoupdate=registry"
      # Camoufox/Firefox needs more than podman's 64m default shm, or it
      # crashes mid-challenge-solve (upstream: ThePhaseless/Byparr#283)
      "--shm-size=1gb"
      "--security-opt=no-new-privileges"
      # Firefox content sandbox needs these for its own userns+chroot; bare cap-drop=all hangs navigation.
      "--cap-drop=all"
      "--cap-add=SYS_CHROOT"
      "--cap-add=SETUID"
      "--cap-add=SETGID"
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
}
