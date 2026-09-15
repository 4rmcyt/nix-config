{config, ...}: {
  virtualisation.oci-containers.containers.seerr = {
    autoStart = true;
    image = "ghcr.io/hotio/seerr:latest";
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--env=PUID=${toString config.users.users.seerr.uid}"
      "--env=PGID=${toString config.users.groups.seerr.gid}"
      "--env=UMASK=002"
      "--env=TZ=${config.my.defaults.timezone}"
      "--security-opt=no-new-privileges"
      # hotio-style s6-overlay init needs these to chown /config and
      # setuid/setgid down to PUID/PGID at startup -- cap-drop=all alone
      # breaks the permission-drop step.
      "--cap-drop=all"
      "--cap-add=CHOWN"
      "--cap-add=DAC_OVERRIDE"
      "--cap-add=FOWNER"
      "--cap-add=KILL"
      "--cap-add=SETGID"
      "--cap-add=SETUID"
    ];
    volumes = [
      "/data/media/.state/nixarr/seerr:/config"
    ];
  };

  systemd.services.podman-seerr = {
    after = ["data.mount"];
    requires = ["data.mount"];
  };
}
