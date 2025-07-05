{ config, pkgs, lib, ... }:

{
  # SOPS secret for Grafana
  sops.secrets.grafana_admin_password = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  # Properly configured Netdata with disabled problematic plugins
  services.netdata = {
    enable = true;
    config = {
      global = {
        "default port" = "19999";
        "bind to" = "0.0.0.0";
        "hostname" = "homeserver";
        "update every" = "3";
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
      };
      # Properly disable problematic plugins
      "plugin:freeipmi" = {
        "enabled" = "no";
        "update every" = "never";
      };
      "plugin:charts.d" = { "enabled" = "no"; };
      "plugin:python.d" = { "enabled" = "no"; };
      "plugin:logs-management" = { "enabled" = "no"; };
      "plugin:ioping" = { "enabled" = "no"; };
      "plugin:perf" = { "enabled" = "no"; };
      "plugin:cgroup-network" = { "enabled" = "no"; };
      "plugin:systemd-journal" = { "enabled" = "no"; };
      "plugin:network-viewer" = { "enabled" = "no"; };
      "plugin:debugfs" = { "enabled" = "no"; };

      # Keep essential plugins enabled
      "plugin:proc" = { "enabled" = "yes"; };
      "plugin:diskspace" = { "enabled" = "yes"; };
      "plugin:cgroups" = { "enabled" = "yes"; };
      "plugin:tc" = { "enabled" = "no"; };  # Traffic control - not needed
      "plugin:apps" = { "enabled" = "yes"; };
      "plugin:go.d" = { "enabled" = "yes"; };
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