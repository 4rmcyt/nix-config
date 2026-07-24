# modules/services/nixarr/seerr/default.nix
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
