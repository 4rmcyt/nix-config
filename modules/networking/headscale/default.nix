{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.headscale;
  inherit (config.my.defaults) domain;

  port = 8080;
  metricsPort = 9091;
in {
  options.my.headscale = {
    enable = mkEnableOption "Headscale coordination server";

    dns = {
      nameservers = mkOption {
        type = types.listOf types.str;
        default = ["45.90.28.163" "45.90.30.163"];
        description = "Global nameservers pushed to Tailnet nodes (e.g. NextDNS).";
      };
      splitNameservers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Nameservers used for split DNS domains. Defaults to nameservers if empty.";
      };
      splitDomains = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Domains to resolve via splitNameservers.";
      };
    };

    derp = {
      regionCode = mkOption {
        type = types.str;
        default = "relay";
        description = "Short DERP region code.";
      };
      regionName = mkOption {
        type = types.str;
        default = "Relay";
        description = "Human-readable DERP region name.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.headscale = {
      enable = true;

      settings = {
        server_url = "https://hs.${domain}";
        listen_addr = "127.0.0.1:${toString port}";
        noise.private_key_path = "/var/lib/headscale/noise_private.key";

        log = {
          level = "info";
          format = "text";
        };
        logtail.enabled = false;

        database = {
          type = "sqlite";
          sqlite.path = "/var/lib/headscale/db.sqlite";
        };

        dns = {
          magic_dns = true;
          base_domain = "ts.${domain}";
          nameservers.global = cfg.dns.nameservers;
          nameservers.split =
            listToAttrs (map (d: {
                name = d;
                value =
                  if cfg.dns.splitNameservers != []
                  then cfg.dns.splitNameservers
                  else cfg.dns.nameservers;
              })
              cfg.dns.splitDomains)
            // config.my.network.tailnetSplitDns;
          search_domains = [];
        };

        derp = {
          server = {
            enabled = true;
            region_id = 901;
            region_code = cfg.derp.regionCode;
            region_name = cfg.derp.regionName;
            stun_listen_addr = "0.0.0.0:3478";
          };
          auto_update_enabled = true;
          urls = ["https://controlplane.tailscale.com/derpmap/default"];
        };

        metrics_listen_addr = "127.0.0.1:${toString metricsPort}";

        policy = {
          mode = "file";
          path = pkgs.writeText "headscale-policy.json" (builtins.toJSON (import ./policy.nix {inherit config;}));
        };
      };
    };

    networking.firewall.allowedUDPPorts = [3478];

    # Upstream module already sets the rest of the sandbox; PrivateUsers is the only addition.
    systemd.services.headscale.serviceConfig.PrivateUsers = mkDefault true;
  };
}
