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
in {
  options.my.kanidmClient = {
    enable = lib.mkEnableOption "Kanidm unix client (SSH key distribution + PAM cache)";
  };

  config = lib.mkIf config.my.kanidmClient.enable {
    services.kanidm = {
      package = lib.mkDefault pkgs.kanidm_1_10;

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
            # Only members of this group can use PAM login (not needed for SSH keys,
            # but required by kanidm_unixd config schema)
            pam_allowed_login_groups = ["users"];
          };
        };
      };
    };
  };
}
