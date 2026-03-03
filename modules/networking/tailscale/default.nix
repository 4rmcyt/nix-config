{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.networking.tailscaleAuth;
in {
  options.networking.tailscaleAuth = {
    enable = mkEnableOption "Tailscale with SOPS authentication";
    sopsFile = mkOption {
      type = types.path;
      description = "Path to the SOPS file containing the auth key";
    };
    key = mkOption {
      type = types.str;
      default = "tailscale_auth_key";
      description = "YAML key for the auth key in the SOPS file";
    };
    loginServer = mkOption {
      type = types.str;
      default = "https://controlplane.tailscale.com";
      description = "Login server URL (use headscale URL for self-hosted coordination)";
    };

    advertiseExitNode = mkOption {
      type = types.bool;
      default = false;
      description = "Advertise this node as a Tailscale exit node";
    };

    advertiseRoutes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Subnet routes to advertise (e.g. [\"192.168.1.0/24\"])";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.tailscale_auth_key = {
      inherit (cfg) sopsFile;
      inherit (cfg) key;
    };

    environment.systemPackages = with pkgs; [
      tailscale
      jq
      ethtool
      networkd-dispatcher
    ];

    services = {
      tailscale = {
        enable = true;
        useRoutingFeatures = "both";
        disableUpstreamLogging = true;
      };
      networkd-dispatcher = {
        enable = true;
        rules."50-tailscale" = {
          onState = ["routable"];
          script = ''
            ${pkgs.ethtool} -K eth0 rx-udp-gro-forwarding on rx-gro-list off
          '';
        };
      };
    };

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";
      after = [
        "network-pre.target"
        "tailscale.service"
      ];
      wants = [
        "network-pre.target"
        "tailscale.service"
      ];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "30";
      };
      script = with pkgs; ''
        sleep 2
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ "$status" = "Running" ]; then
          current_url="$(${tailscale}/bin/tailscale debug prefs | ${jq}/bin/jq -r .ControlURL)"
          if [ "$current_url" = "${cfg.loginServer}" ]; then
            exit 0
          fi
          ${tailscale}/bin/tailscale logout || true
        fi
        ${tailscale}/bin/tailscale up \
          --authkey file:${config.sops.secrets.tailscale_auth_key.path} \
          --login-server ${cfg.loginServer} \
          --accept-routes \
          ${optionalString cfg.advertiseExitNode "--advertise-exit-node"} \
          ${optionalString (cfg.advertiseRoutes != []) "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"}
      '';
    };
  };
}
