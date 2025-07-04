{ config, pkgs, lib, ... }:

{
  sops.secrets.hass_postgres_password = {
    owner = "hass";
    group = "hass";
    mode = "0400";
  };

  services.home-assistant = {
    enable = true;
    
    extraPackages = python3Packages: with python3Packages; [
      psycopg2
      getmac  # Add this to fix UPnP component
      aioamazondevices
      rokuecp

    ];
    
    extraComponents = [
      "default_config"
      "met"
      "esphome"
      "shopping_list"
      "recorder"
      "history"
    ];

    config = {
      default_config = {};

      http = {
        server_host = "0.0.0.0";
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" "192.168.1.165" ];
      };

      recorder = {
        db_url = "postgresql://homeassistant:!secret db_password@localhost/homeassistant";
        purge_keep_days = 10;
        auto_purge = true;
      };
    };
  };

  systemd.services.home-assistant-secrets = {
    description = "Create Home Assistant secrets file";
    before = [ "home-assistant.service" ];
    wantedBy = [ "home-assistant.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "create-hass-secrets" ''
        mkdir -p /var/lib/hass
        echo "db_password: $(cat ${config.sops.secrets.hass_postgres_password.path})" > /var/lib/hass/secrets.yaml
        chown hass:hass /var/lib/hass/secrets.yaml
        chmod 600 /var/lib/hass/secrets.yaml
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];
}