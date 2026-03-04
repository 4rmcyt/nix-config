{
  config,
  ...
}: let
  inherit (config.my.defaults) homeserver_lan timezone;
in {
  # ── OCI Container ─────────────────────────────────────────────────────────
  # Backend (podman) is set in modules/containers/default.nix — no need to repeat.
  virtualisation.oci-containers.containers.homeassistant = {
    autoStart = true;
    environment.TZ = timezone;
    extraOptions = [
      "--network=host"
      # USB passthrough for Zigbee/Z-Wave dongle (uncomment + adjust device path):
      # "--device=/dev/ttyACM0:/dev/ttyACM0"
    ];
    image = "ghcr.io/home-assistant/home-assistant:stable";
    volumes = ["/var/lib/hass:/config"];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/hass 0750 root root -"
  ];

  # ── Mosquitto MQTT Broker ─────────────────────────────────────────────────
  # HA container (--network=host) connects to mosquitto via homeserver_lan:1883.
  # IoT devices on the LAN also reach the broker at this address.
  users.users.mosquitto = {
    isSystemUser = true;
    group = "mosquitto";
  };
  users.groups.mosquitto = {};

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = homeserver_lan;
        port = 1883;
        acl = ["pattern readwrite #"];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [1883];
}
