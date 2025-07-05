
{ config, pkgs, lib, ... }:

{
  # SOPS secret for Grafana
  sops.secrets.grafana_admin_password = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  # Fixed Netdata configuration with proper web settings
  services.netdata = {
    enable = true;
    config = {
      global = {
        "default port" = "19999";
        "bind to" = "0.0.0.0";
        "hostname" = "homeserver";
        "update every" = "1";
        "memory mode" = "ram";
        "history" = "3600";
      };
      web = {
        "bind to" = "0.0.0.0";
        "allow connections from" = "*";
        "allow dashboard from" = "*";
        "allow badges from" = "*";
        "allow streaming from" = "*";
        "allow netdata.conf from" = "*";
        "allow management from" = "*";
        "web files owner" = "root";
        "web files group" = "root";
        "disconnect idle clients after seconds" = "60";
        "timeout for first request" = "60";
        "accept a streaming request every seconds" = "2";
        "respect do not track policy" = "no";
        "x-frame-options response header" = "";
        "enable gzip compression" = "yes";
      };
      # Disable health monitoring that might cause issues
      "health" = {
        "enabled" = "no";
      };
    };
  };

  # Prometheus monitoring server
  services.prometheus = {
    enable = true;
    port = 9090;
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:9100" ];
          labels = { instance = "homeserver"; };
        }];
      }
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "localhost:9090" ];
          labels = { instance = "homeserver"; };
        }];
      }
    ];
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";
      };
      security = {
        admin_user = "admin";
        admin_password_file = config.sops.secrets.grafana_admin_password.path;
      };
      "auth.anonymous" = { enabled = false; };
      analytics = { reporting_enabled = false; };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:9090";
          isDefault = true;
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 9090 9100 3000 19999 ];
}