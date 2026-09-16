{config, ...}: {
  virtualisation.oci-containers.containers.trawl = {
    autoStart = true;
    image = "ghcr.io/germondai/trawl:latest";
    environment = {
      TZ = config.my.defaults.timezone;
      # No external Redis for this trial -- bounded in-process cache is enough
      # at BROWSER_POOL_SIZE=1, and keeps trawl self-contained to rip out if
      # it doesn't pan out against Byparr.
      SESSION_CACHE_DRIVER = "memory";
    };
    # Bound to loopback like dispatcharr -- Prowlarr calls it over 127.0.0.1,
    # no LAN exposure needed.
    ports = ["127.0.0.1:8193:8191"];
    extraOptions = [
      "--label=io.containers.autoupdate=registry"
      # Camoufox/Firefox needs more than podman's 64m default shm (same
      # reasoning as byparr's --shm-size).
      "--shm-size=1gb"
      "--security-opt=no-new-privileges"
      # Diagnostic: byparr and trawl are both Firefox-based (playwright/camoufox)
      # and both hang forever on real page navigation with --cap-drop=all set,
      # while health/pool-warmup (no navigation) work fine. Testing whether
      # Firefox's content-process spawn needs something this strips. Re-add
      # once we know which capability (if any) is actually required.
      # "--cap-drop=all"
    ];
  };
}
