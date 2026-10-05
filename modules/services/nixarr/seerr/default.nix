{config, ...}: let
  inherit (config.my.network) ports;
  port = toString ports.seerr;
in {
  virtualisation.oci-containers.containers.seerr = {
    autoStart = true;
    image = "ghcr.io/hotio/seerr:latest";
    # Reverse proxy only; published ports are DNAT'd past the NixOS firewall, so loopback-only.
    ports = ["127.0.0.1:${port}:${port}"];
    extraOptions = [
      # PUID/PGID are set at runtime, not in the image passwd, so pin the range size instead of auto-estimating.
      "--userns=auto:size=65536"
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
      "/data/media/.state/nixarr/seerr:/config:idmap"
    ];
  };

  systemd.services.podman-seerr = {
    after = ["data.mount"];
    requires = ["data.mount"];
  };

  # Jellyfin/Radarr/Sonarr on the host, reached via host.containers.internal.
  networking.firewall.interfaces.podman0.allowedTCPPorts = [ports.jellyfin ports.radarr ports.sonarr];
}
