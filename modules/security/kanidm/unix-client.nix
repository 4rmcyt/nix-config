# Kanidm unix daemon + SSH key integration for client machines.
# Enables kanidm_unixd for SSH public key lookup with local caching.
# Static authorized_keys in host configs remain as fallback.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.my.defaults) domain;
  kanidmVersion = import ./version.nix;
in {
  options.my.kanidmClient = {
    enable = lib.mkEnableOption "Kanidm unix client (SSH key distribution + PAM cache)";
  };

  config = lib.mkIf config.my.kanidmClient.enable {
    services.kanidm = {
      # services.kanidm.package is shared by kanidmd/unixd/nss — there is no
      # separate option per role. On hosts that also import ./default.nix with
      # provisioning enabled (currently homeserver), this mkDefault is overridden
      # by the hard-set kanidmWithSecretProvisioning_${kanidmVersion} package,
      # since kanidm's own module asserts that provisioning secrets require the
      # secret-provisioning build. That's required, not a bug — see
      # nixos/modules/services/security/kanidm.nix upstream.
      package = lib.mkDefault pkgs."kanidm_${kanidmVersion}";

      client = {
        enable = true;
        settings.uri = "https://idm.${domain}";
      };

      unix = {
        enable = true;
        sshIntegration = true;
        settings = {
          version = "2";
          kanidm = {
            uri = "https://idm.${domain}";
            pam_allowed_login_groups = ["users"];
          };
        };
      };
    };
  };
}
