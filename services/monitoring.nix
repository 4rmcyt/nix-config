
{ config, pkgs, lib, ... }:

{
  # SOPS secret for Grafana
  sops.secrets.grafana_admin_password = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  # Official NixOS Wiki approach for Netdata
  services.netdata = {
    enable = true;
    # Use default configuration as recommended by NixOS Wiki
    config = {
      global = {
        "default port" = "19999";
        "bind to" = "*";
      };
      web = {
        "web files owner" = "root";
        "web files group" = "root";
      };
    };
  };

  # Ensure netdata user has proper permissions
  users.users.netdata = {
    extraGroups = [ "systemd-journal" ];
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
      {
        job_name = "netdata";
        static_configs = [{
          targets = [ "localhost:19999" ];
          labels = { instance = "homeserver"; };
        }];
        metrics_path = "/api/v1/allmetrics";
        params = {
          format = ["prometheus"];
        };
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