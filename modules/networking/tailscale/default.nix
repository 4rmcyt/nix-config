{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.tailscale;
in
{
  options.services.tailscale = {
    enable = mkEnableOption "Custom Tailscale module";
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
      sopsFile = cfg.sopsFile;
      key = cfg.key;
    };

    users.users.tailscale = {
      isSystemUser = true;
      group = "tailscale";
    };
    users.groups.tailscale = { };

    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

    environment.systemPackages = [ pkgs.tailscale ];
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = with pkgs; ''
        ${tailscale}/bin/tailscale up --authkey file:${config.sops.secrets.tailscale_auth_key.path} --accept-routes
      '';
    };
  };
}
