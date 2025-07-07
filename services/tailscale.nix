# /etc/nixos/services/tailscale.nix
{ config, pkgs, ... }:

{
  # Enable the Tailscale service
  services.tailscale.enable = true;

  # Define the sops secret for the auth key
  sops.secrets.tailscale_auth_key = {};

  # Use a systemd service to authenticate the node on first boot
  # or if the node key expires.
  systemd.services.tailscale-auth = {
    description = "Tailscale Authentication";
    # This should only run once after the main service starts
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscale.service" ];

    # This condition ensures it only runs if the node is not already authenticated
    conditionPathExists = "!/var/lib/tailscale/tailscaled.state";

    script = ''
      # Authenticate using the pre-auth key from sops
      ${pkgs.tailscale}/bin/tailscale up --authkey-file=${config.sops.secrets.tailscale_auth_key.path}
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}