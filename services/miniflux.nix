# /etc/nixos/services/miniflux.nix
#
# Configures the Miniflux RSS reader service, using the official
# NixOS module options.

{ config, pkgs, ... }:

{
  # This defines the SOPS secret for the Miniflux admin password.
  # sops-nix will look for a key named 'miniflux_admin_password' in your default secrets.yaml.
  sops.secrets.miniflux_admin_password = {};

  # This configures the Miniflux service using the standard NixOS module options.
  services.miniflux = {
    enable = true;

    # The 'config' block is used to set environment variables for Miniflux.
    config = {
      # This sets the service to listen on the local interface at port 8086.
      LISTEN_ADDR = "127.0.0.1:8086";

      # --- CORRECTED OPTIONS ---
      # The admin credentials must be set as environment variables.
      ADMIN_USERNAME = "admin";
      ADMIN_PASSWORD_FILE = config.sops.secrets.miniflux_admin_password.path;
    };
  };
}
