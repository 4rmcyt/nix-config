# modules/services/nixarr/byparr/default.nix
_: {
  virtualisation.oci-containers.containers.byparr = {
    autoStart = true;
    image = "ghcr.io/thephaseless/byparr:latest";
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      # Camoufox/Firefox needs more than podman's 64m default shm, or it
      # crashes mid-challenge-solve (upstream: ThePhaseless/Byparr#283)
      "--shm-size=1gb"
    ];
    environment = {
      PORT = "8191";
    };
  };

  networking.firewall.allowedTCPPorts = [
    8191 # Byparr (FlareSolverr-compatible Cloudflare bypass)
  ];
}
