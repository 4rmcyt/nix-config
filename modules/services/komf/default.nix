{config, ...}: let
  port = toString config.my.network.ports.komf;
in {
  virtualisation.oci-containers.containers.komf = {
    autoStart = true;
    image = "docker.io/sndxr/komf:latest";
    # Reverse proxy only; published ports are DNAT'd past the NixOS firewall, so loopback-only.
    ports = ["127.0.0.1:${port}:${port}"];
    extraOptions = [
      # media gid comes from --user, not the image passwd, so pin the range size instead of auto-estimating.
      "--userns=auto:size=65536"
      # Bridge DNS can't see the LAN split-horizon; application.yml points at https://komga.<domain> via host Caddy.
      "--add-host=komga.${config.my.defaults.domain}:host-gateway"
      "--label=io.containers.autoupdate=registry"
      "--user=0:${toString config.users.groups.media.gid}"
      "--env=TZ=${config.my.defaults.timezone}"
      "--env=JAVA_TOOL_OPTIONS=-XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahGC -XX:ShenandoahGCHeuristics=compact -XX:ShenandoahGuaranteedGCInterval=3600000 -XX:TrimNativeHeapInterval=3600000"
      "--security-opt=no-new-privileges"
      # Runs as root:media (--user=0:gid above) writing into group-owned
      # manga/comics dirs -- keep CHOWN, drop everything else.
      "--cap-drop=all"
      "--cap-add=CHOWN"
    ];
    volumes = [
      "/var/lib/komf:/config:idmap"
      "/data/media/manga:/data/media/manga:idmap"
      "/data/media/comics:/data/media/comics:idmap"
    ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/komf 0750 root root -"
  ];
}
