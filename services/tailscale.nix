
{ config, pkgs, lib, ... }:

{
  # SOPS secret for Tailscale auth key
  sops.secrets.tailscale_auth_key = {};

  # Enable Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";  # Enable subnet routing and exit nodes
  };

  # Enable tailscale daemon
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up --authkey file:${config.sops.secrets.tailscale_auth_key.path} --accept-routes
    '';
  };

  # REMOVED: IP forwarding (now handled centrally in networking.nix)
  # This prevents duplicate sysctl definitions

  # Allow Tailscale UDP port
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}