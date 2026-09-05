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
      description = "Path to the SOPS file containing the auth key (YAML key: tailscale_auth_key)";
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

    networkInterface = mkOption {
      type = types.str;
      default = "eth0";
      description = "Network interface for ethtool GRO offload tuning.";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.tailscale_auth_key = {
      inherit (cfg) sopsFile;
      key = "tailscale_auth_key";
    };

    environment.systemPackages = with pkgs; [
      tailscale
      jq
      ethtool
    ];

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      disableUpstreamLogging = true;
    };

    # Tunes GRO offload for Tailscale throughput. Runs as a plain oneshot
    # bound to the interface's device unit instead of networkd-dispatcher,
    # since this host doesn't use systemd-networkd (networkd-dispatcher's
    # rules never fire without it).
    systemd.services.tailscale-ethtool-tune = {
      description = "Tune GRO offload on ${cfg.networkInterface} for Tailscale";
      after = [
        "network-online.target"
        "sys-subsystem-net-devices-${cfg.networkInterface}.device"
      ];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.ethtool}/bin/ethtool -K ${cfg.networkInterface} rx-udp-gro-forwarding on rx-gro-list off";
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
          if [ "$current_url" != "${cfg.loginServer}" ]; then
            ${tailscale}/bin/tailscale logout || true
            ${tailscale}/bin/tailscale up \
              --authkey file:${config.sops.secrets.tailscale_auth_key.path} \
              --login-server ${cfg.loginServer} \
              --accept-routes \
              ${optionalString cfg.advertiseExitNode "--advertise-exit-node"} \
              ${optionalString (cfg.advertiseRoutes != []) "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"}
          else
            ${tailscale}/bin/tailscale set \
              --accept-routes=true \
              ${optionalString cfg.advertiseExitNode "--advertise-exit-node"} \
              ${optionalString (cfg.advertiseRoutes != []) "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"}
          fi
        else
          ${tailscale}/bin/tailscale up \
            --authkey file:${config.sops.secrets.tailscale_auth_key.path} \
            --login-server ${cfg.loginServer} \
            --accept-routes \
            --reset \
            ${optionalString cfg.advertiseExitNode "--advertise-exit-node"} \
            ${optionalString (cfg.advertiseRoutes != []) "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"}
        fi
      '';
    };
  };
}
