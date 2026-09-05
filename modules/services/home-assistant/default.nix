{config, ...}: let
  inherit (config.my.defaults) domain timezone;
  inherit (config.my.network.hosts) homeserver_lan desktop_lan desktop_wifi;
  inherit (config.my.network.mac) desktop-wifi desktop-lan;
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
    mode = "0400";
    content = ''
      # Loads default set of integrations. Do not remove.
      default_config:

      homeassistant:
        external_url: "https://hass.${domain}"
        internal_url: "http://localhost:${toString config.my.network.ports.home-assistant}"

      frontend:
        themes: !include_dir_merge_named themes

      automation: !include automations.yaml
      script: !include scripts.yaml
      scene: !include scenes.yaml

      wake_on_lan:

      switch:
        - platform: wake_on_lan
          name: "Desktop (LAN)"
          mac: "${desktop-lan}"
          host: ${desktop_lan}
        - platform: wake_on_lan
          name: "Desktop (WiFi)"
          mac: "${desktop-wifi}"
          host: ${desktop_wifi}

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
      "--label=io.containers.autoupdate=registry"
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
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
  # HA container (--network=host) connects to mosquitto via homeserver_lan on
  # config.my.network.ports.mosquitto.
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
        port = config.my.network.ports.mosquitto;
        acl = ["pattern readwrite #"];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [config.my.network.ports.mosquitto];
}
