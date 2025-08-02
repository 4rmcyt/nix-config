{
  config,
  pkgs,
  lib,
  ...
}:

{

  sops.secrets = {
    grafana_admin_password = {
      sopsFile = ../../secrets/grafana.yaml;
      key = "grafana_admin_password";
      owner = config.users.users.grafana.name;
      group = config.users.groups.grafana.name;
      mode = "0400";
    };
    # You will need to create this secret file and add your NextDNS API key
    nextdns_api_key = {
      sopsFile = ../../secrets/nextdns.yaml;
      key = "nextdns_api_key";
      owner = config.users.users.prometheus.name;
    };
  };

  users.users = {
    grafana = {
      isSystemUser = true;
      group = "grafana";
      extraGroups = [ "users" ];
    };
    uptime-kuma = {
      isSystemUser = true;
      group = "uptime-kuma";
      extraGroups = [
        "users"
        "podman"
      ];
    };
    prometheus = {
      isSystemUser = true;
      group = "prometheus";
      extraGroups = [ "users" ];
    };
  };

  users.groups = {
    grafana = { };
    uptime-kuma = { };
    prometheus = { };
  };

  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
    9090 # Prometheus
    9100 # Node Exporter
    9948 # NextDNS Exporter
    3001 # Uptime Kuma
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "prometheus.example.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:9090";
          proxyWebsockets = true;
        };
      };
      "uptime-kuma.example.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:3001";
          proxyWebsockets = true;
        };
      };
      "grafana.example.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/grafana/" = {
          # FIX: Added trailing slash to correctly handle the subpath
          proxyPass = "http://localhost:3000/";
          proxyWebsockets = true;
        };
      };
    };
  };

  environment.systemPackages = [
    pkgs.grafana
    pkgs.prometheus
    pkgs.prometheus-node-exporter
    # FIX: Added the exporter package to the system
    pkgs.nextdns-exporter
  ];

  # FIX: Added systemd service for the NextDNS exporter
  systemd.services.nextdns-exporter = {
    description = "NextDNS Prometheus Exporter";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = ''
        ${pkgs.nextdns-exporter}/bin/nextdns-exporter \
          -listen-address "127.0.0.1:9948" \
          -api-key-file "${config.sops.secrets.nextdns_api_key.path}"
      '';
      Restart = "on-failure";
      User = config.users.users.prometheus.name;
    };
  };

  services.prometheus = {
    enable = true;
    port = 9090;
    globalConfig = {
      scrape_interval = "5s";
      evaluation_interval = "5s";
    };

    scrapeConfigs = [
      {
        job_name = "node-exporter";
        static_configs = [{
          targets = [ "localhost:9100" ];
          labels = { instance = "homeserver"; };
        }];
        scrape_interval = "2s";
      }
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "localhost:9090" ];
          labels = { instance = "homeserver"; };
        }];
      }
      {
        job_name = "nextdns-exporter";
        static_configs = [{
          # FIX: This target will now work because the service is defined
          targets = [ "localhost:9948" ];
          labels = { instance = "homeserver"; };
        }];
      }
    ];

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "processes"
          "interrupts"
          "cpu"
          "diskstats"
          "meminfo"
          "netdev"
          "netstat"
          "btrfs"
          "stat"
          "time"
          "thermal_zone"
          "hwmon"
        ];
        port = 9100;
      };
    };

    ruleFiles = [
      (pkgs.writeText "homeserver-alerts.yml" ''
        groups:
          - name: homeserver
            rules:
              - alert: HighCPUUsage
                expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "High CPU usage detected on {{ $labels.instance }}"
      '')
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        # BEST PRACTICE: Bind to localhost as it's behind a proxy
        http_addr = "127.0.0.1";
        # FIX: Set root_url to the public-facing URL and subpath
        root_url = "https://grafana.example.com/grafana";
        # FIX: Tell Grafana it's being served from a subpath
        serve_from_sub_path = true;
      };
      database = {
        type = "postgres";
        host = "/run/postgresql";
        user = "grafana";
        password = config.sops.secrets.grafana_db_password.path;
      };
      security = {
        admin_user = "admin";
        admin_password_file = config.sops.secrets.grafana_admin_password.path;
      };
    };

    provision.enable = true;
    provision.datasources.settings.datasources = [{
      name = "Prometheus";
      type = "prometheus";
      access = "proxy";
      url = "http://localhost:9090";
      isDefault = true;
    }];

    provision.dashboards.settings.providers = [
      {
        name = "System Dashboard";
        type = "file";
        options.path = "/etc/grafana/dashboards/system.json";
        options.foldersFromFilesStructure = true;
      }
      {
        name = "Custom Dashboards";
        type = "file";
        # FIX: Point to a dedicated 'dashboards' subdirectory
        # You must create this folder next to your .nix file
        options.path = ./dashboards;
        options.foldersFromFilesStructure = true;
      }
    ];
  };

  services.uptime-kuma = {
    enable = true;
    settings = {
      port = "3001";
      bind_address = "127.0.0.1";
    };
  };

  # REMOVED: Redundant systemd.tmpfiles.rules.
  # The Grafana module handles its own directory creation.
}