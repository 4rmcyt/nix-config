# modules/services/komf/default.nix
{config, ...}: {
  virtualisation.oci-containers.containers.komf = {
    autoStart = true;
    image = "docker.io/sndxr/komf:latest";
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--user=0:${toString config.users.groups.media.gid}"
      "--env=TZ=${config.my.defaults.timezone}"
      "--env=JAVA_TOOL_OPTIONS=-XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahGC -XX:ShenandoahGCHeuristics=compact -XX:ShenandoahGuaranteedGCInterval=3600000 -XX:TrimNativeHeapInterval=3600000"
    ];
    volumes = [
      "/var/lib/komf:/config"
      "/data/media/manga:/data/media/manga"
      "/data/media/comics:/data/media/comics"
    ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/komf 0750 root root -"
  ];
}
