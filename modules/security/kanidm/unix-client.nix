# Deliberately avoids unix.enable/sshIntegration: kanidm's POSIX model forces uid ==
# gid, which local users with a separate shared primary group can't represent.
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
    enable = lib.mkEnableOption "Kanidm SSH key distribution (direct mode)";
  };

  config = lib.mkIf config.my.kanidmClient.enable {
    services.kanidm = {
      package = lib.mkDefault pkgs."kanidm_${kanidmVersion}";

      client = {
        enable = true;
        settings.uri = "https://idm.${domain}";
      };
    };

    # sshd refuses an AuthorizedKeysCommand under /nix/store (group-writable, fails its
    # ownership check) — route through security.wrappers instead. See NixOS/nixpkgs#94653.
    security.wrappers.kanidm_ssh_authorizedkeys_direct = {
      owner = "root";
      group = "root";
      permissions = "a+rx";
      source = "${config.services.kanidm.package}/bin/kanidm_ssh_authorizedkeys_direct";
    };

    services.openssh.settings = {
      AuthorizedKeysCommand = "${config.security.wrapperDir}/kanidm_ssh_authorizedkeys_direct -D anonymous %u";
      AuthorizedKeysCommandUser = "nobody";
    };
  };
}
