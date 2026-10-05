_: {
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "podman";

  # Rootful --userns=auto carves per-container ranges out of the "containers" subuid/subgid entry (podman-run(1)).
  users.users.containers = {
    isSystemUser = true;
    group = "containers";
    subUidRanges = [
      {
        startUid = 2147483647;
        count = 2147483648;
      }
    ];
    subGidRanges = [
      {
        startGid = 2147483647;
        count = 2147483648;
      }
    ];
  };
  users.groups.containers = {};

  virtualisation.containers.policy = {
    default = [{type = "insecureAcceptAnything";}];
  };

  systemd.timers.podman-auto-update = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "04:00:00";
      Persistent = true;
    };
  };
}
