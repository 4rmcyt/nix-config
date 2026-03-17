{config, ...}: let
  inherit (config.my.defaults) domain homeserver_lan timezone;
in {
  sops.secrets.hass_alexa_client_secret = {
    sopsFile = ../../../secrets/hass-alexa.yaml;
    key = "alexa_client_secret";
    owner = "root";
    mode = "0400";
  };

  # ── OCI Container ─────────────────────────────────────────────────────────
  # Backend (podman) is set in modules/containers/default.nix — no need to repeat.
  # Declarative configuration.yaml — injected via sops template (contains secrets).
  # HA never writes to this file; automations/scripts/scenes go to separate includes.
  sops.templates."homeassistant-configuration.yaml" = {
    owner = "root";
    mode = "0444";
    content = ''
      # Loads default set of integrations. Do not remove.
      default_config:

      homeassistant:
        external_url: "https://hass.${domain}"
        internal_url: "http://localhost:8123"

      frontend:
        themes: !include_dir_merge_named themes

      automation: !include automations.yaml
      script: !include scripts.yaml
      scene: !include scenes.yaml

      # Required for reverse proxy
      http:
        use_x_forwarded_for: true
        trusted_proxies:
          - 127.0.0.1
          - ::1

      alexa:
        smart_home:
          endpoint: https://api.amazonalexa.com/v3/events
          client_id: "https://pitangui.amazon.com/"
          client_secret: "${config.sops.placeholder.hass_alexa_client_secret}"
    '';
  };

  virtualisation.oci-containers.containers.homeassistant = {
    autoStart = true;
    environment.TZ = timezone;
    extraOptions = [
      "--network=host"
      # USB passthrough for Zigbee/Z-Wave dongle (uncomment + adjust device path):
      # "--device=/dev/ttyACM0:/dev/ttyACM0"
    ];
    image = "ghcr.io/home-assistant/home-assistant:stable";
    volumes = [
      "/var/lib/hass:/config"
      "${config.sops.templates."homeassistant-configuration.yaml".path}:/config/configuration.yaml:ro"
    ];
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
