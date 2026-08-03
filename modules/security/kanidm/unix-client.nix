# Kanidm SSH key distribution for client machines, via direct HTTP lookup
# (kanidm_ssh_authorizedkeys_direct) rather than the kanidm_unixd/PAM path.
#
# We deliberately avoid unix.enable/sshIntegration (kanidm_unixd + NSS/PAM
# integration): those require the account to have kanidm's POSIX extension,
# and kanidm's POSIX model forces uid == gid on a single "gidnumber" value.
# Our local NixOS users already have a fixed uid with a separate shared
# primary group (e.g. zeev: uid=1000, group "users" gid=100), which cannot be
# represented that way — enabling it would make NSS resolve a different
# uid/gid for the same username and desync home directory ownership.
#
# Direct mode just queries the server over HTTPS for SSH public keys and
# leaves the local unix account (uid/gid/home) fully authoritative. Trade-off:
# no offline key cache, so SSH auth needs reachability to idm.${domain}.
# Static authorized_keys in host configs remain as fallback regardless.
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

    # sshd refuses an AuthorizedKeysCommand that lives under /nix/store: the
    # store directory itself is group-writable (root:nixbld, drwxrwxr-t),
    # which fails sshd's "bad ownership or modes" check on the whole path,
    # not just the binary. Route through security.wrappers instead, which
    # places the binary in wrapperDir (root-owned, not writable by others) —
    # the same workaround the upstream kanidm NixOS module uses for its own
    # sshIntegration path. See NixOS/nixpkgs#94653.
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
