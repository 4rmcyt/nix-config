{ config, pkgs, lib, ... }:

{
  # SOPS secret for Grafana
  sops.secrets.grafana_admin_password = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  # Fixed Netdata configuration with proper web directory
  services.netdata = {
    enable = true;
    config = {
      global = {
        "default port" = "19999";
        "bind to" = "*";
        "hostname" = "homeserver";
        "update every" = "3";
        "memory mode" = "ram";
        "history" = "3600";
        # Explicitly set web files directory
        "web files directory" = "${pkgs.netdata}/share/netdata/web";
      };
      web = {
        "bind to" = "*";
        "allow connections from" = "*";
        "allow dashboard from" = "*";
        "allow badges from" = "*";
        "allow streaming from" = "*";
        "allow netdata.conf from" = "*";
        "allow management from" = "*";
        # Ensure web files permissions
        "web files owner" = "root";
        "web files group" = "root";
      };
      # Disable problematic plugins
      "plugin:freeipmi" = { "enabled" = "no"; };
      "plugin:charts.d" = { "enabled" = "no"; };
      "plugin:python.d" = { "enabled" = "no"; };
      "plugin:logs-management" = { "enabled" = "no"; };
      "plugin:ioping" = { "enabled" = "no"; };
      "plugin:perf" = { "enabled" = "no"; };
      # Disable network cgroup plugin that's causing errors
      "plugin:cgroup-network" = { "enabled" = "no"; };
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
      # Disable netdata scraping for now to avoid errors
      # {
      #   job_name = "netdata";
      #   static_configs = [{
      #     targets = [ "localhost:19999" ];
      #     labels = { instance = "homeserver"; };
      #   }];
      #   metrics_path = "/api/v1/allmetrics";
      #   params = { format = ["prometheus"]; };
      # }
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