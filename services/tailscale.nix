
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = [ pkgs.tailscale ];
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both"; 
  };

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

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  users.users.tailscale = {
    isSystemUser = true;
    group = "tailscale";
    extraGroups = [ "networkmanager" "users" "tailscale" ];
  };
  users.groups.tailscale = { };
}

# Generated new OAuth client
# k3bSghrrmL11CNTRL
# tskey-client-k3bSghrrmL11CNTRL-1dXRywBntC7rrhkHPVCGC7m6iv3VxqkXe