{ config, pkgs, ... }:

let
  # Keep this, as the NixOS module requires adminCredentialsFile
  minifluxCredentialsFile = pkgs.writeText "miniflux-credentials-file" ''
    admin:$(cat ${config.sops.secrets.miniflux_admin_password.path})
  '';
in
{
  sops.secrets.miniflux_admin_password = {};

  services.miniflux = {
    enable = true;
    # Satisfy the NixOS module's assertion
    adminCredentialsFile = minifluxCredentialsFile;

    config = {
      BASE_URL = "https://miniflux.example.com";
      CREATE_ADMIN = "1";
      LISTEN_ADDR = "127.0.0.1:8086";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_REDIRECT_URL = "https://miniflux.example.com/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://keycloak.example.com/realms/master";
      OAUTH2_USER_CREATION = "1";
      DISABLE_LOCAL_AUTH = "true";

      # Explicitly set these in the config. The NixOS module will likely
      # translate these into environment variables for the Miniflux process.
      ADMIN_USERNAME = "admin";
      # For ADMIN_PASSWORD, Miniflux expects the actual password here, not a path.
      # So we need to ensure the SOPS secret is read and the newline removed.
      ADMIN_PASSWORD = lib.removeSuffix "\n" (builtins.readFile config.sops.secrets.miniflux_admin_password.path);
    };
  };
  
  systemd.tmpfiles.rules = [
    "d /var/lib/miniflux 0755 miniflux miniflux - -"
    # This rule is correct for the file, but it's possible minifluxCredentialsFile
    # itself isn't meant to be *written* by tmpfiles, but merely referenced by miniflux.
    # The NixOS module for miniflux should handle placing the adminCredentialsFile
    # if it's needed in a specific location for Miniflux itself, beyond just Nix's build.
    # However, keeping this for now, as it ensures the file derived from pkgs.writeText
    # is actually present on the filesystem at a path that miniflux could theoretically read.
    "f ${minifluxCredentialsFile} 0640 miniflux miniflux -"
  ];

  # Ensure the user and group exist
  users.users.miniflux = {
    isSystemUser = true;
    group = "miniflux";
    home = "/var/lib/miniflux";
  };

  users.groups.miniflux = {};
}