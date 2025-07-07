# /etc/nixos/services/miniflux.nix
#
# Configures the Miniflux RSS reader service, using the official
# NixOS module options.

{ config, pkgs, ... }:

let
  # The miniflux module requires a credentials file in the format "user:password".
  # This 'let' block creates that file declaratively using the password from SOPS.
  minifluxCredentials = pkgs.writeText "miniflux-credentials" ''
    admin:$(cat ${config.sops.secrets.miniflux_admin_password.path})
  '';
in
{
  # This defines the SOPS secret for the Miniflux admin password.
  sops.secrets.miniflux_admin_password = {};

  # This configures the Miniflux service using the standard NixOS module options.
  services.miniflux = {
    enable = true;

    # --- CORRECTED OPTION ---
    # This uses the `adminCredentialsFile` option, which satisfies the
    # module's assertion check for creating the initial admin user.
    adminCredentialsFile = minifluxCredentials;

    # The 'config' block is used to set environment variables for Miniflux.
    config = {
      # This sets the service to listen on the local interface at port 8086.
      LISTEN_ADDR = "127.0.0.1:8086";
    };
  };
}
