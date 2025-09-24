{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.networking.tailscaleAuth;
in
{
  options.networking.tailscaleAuth = {
    enable = mkEnableOption "Tailscale with SOPS authentication";
    sopsFile = mkOption {
      type = types.path;
      description = "Path to the SOPS file containing the Tailscale auth key";
    };
    key = mkOption {
      type = types.str;
      default = "tailscale_auth_key";
      description = "YAML key for the Tailscale auth key";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.tailscale_auth_key = {
      inherit (cfg) sopsFile;
      inherit (cfg) key;
    };

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
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
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = with pkgs; ''
        sleep 2
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then
          exit 0
        fi
        ${tailscale}/bin/tailscale up --authkey file:${config.sops.secrets.tailscale_auth_key.path} --accept-routes
      '';
    };
  };
}
