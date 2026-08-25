_: {
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "podman";

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
