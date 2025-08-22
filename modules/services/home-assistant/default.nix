{
  config,
  pkgs,
  ...
}:
{
  sops.secrets = {
    # --- Home Assistant Secrets ---
    home_assistant_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "hash_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
  };
  users = {
    users = {
      hash = {
        isSystemUser = true;
        group = "hash";
      };
      mosquito = {
        isSystemUser = true;
        group = "mosquito";
      };
    };
    groups = {
      mosquito = { };
      hash = { };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      8123 # Home Assistant
      1883 # MQTT
    ];
    allowedUDPPorts = [
      1883 # MQTT
    ];
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."hash.labhome.work" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
      locations."/" = {
        proxyPass = "http://localhost:8123";
        proxyWebsockets = true;
      };
    };
  };
  environment.systemPackages = with pkgs; [
    home-assistant
    mosquito
  ];
  services = {
    home-assistant = {
      enable = true;
      configDir = "/var/lib/home-assistant";
      configWritable = true;
      extraPackages = ps: [
        ps.psycopg2
        ps.pyatv
      ];
      extraComponents = [
        "mqtt"
        "http"
        "roku"
        "alexa_devices"
        "upnp"
        "radio_browser"
        "met"
        "paperless_ngx"
        "playstation_network"
        "jellyfin"
      ];
      config = {
        homeassistant = {
          name = "Lab Home";
          unit_system = "metric";
          time_zone = "America/Edmonton";
          country = "CA";
          currency = "CAD";
          external_url = "https://hash.labhome.work";
          internal_url = "http://192.168.1.165:8123";
        };
        config.recorder.db_url = "postgresql://@/hash";

        http = {
          server_host = "0.0.0.0";
          server_port = 8123;
          use_x_forwarded_for = true;
          trusted_proxies = [
            "127.0.0.1"
            "192.168.1.165"
          ];
          ip_ban_enabled = true;
          login_attempts_threshold = 5;
        };

        tts = [
          {
            platform = "google_translate";
            language = "en";
          }
        ];

        mqtt = { };

        default_config = { };
        frontend = {
          themes = "!include_dir_merge_named themes";
        };
        shopping_list = { };
        map = { };
        system_health = { };
        logger = {
          default = "info";
          logs = {
            "homeassistant.core" = "debug";
          };
        };
      };
    };

    mosquito = {
      enable = true;
      listeners = [
        {
          acl = [ "pattern readwrite #" ];
          omitPasswordAuth = true;
          settings.allow_anonymous = true;
        }
      ];
    };
  };
}
