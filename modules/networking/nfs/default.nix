{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.my.network) subnets;
in {
  services.nfs.server = {
    enable = true;
    nproc = 8;
    exports = lib.concatStringsSep "\n" (
      (map (subnet: "/data  ${subnet}(rw,sync,no_subtree_check,no_root_squash,insecure)") subnets.lan)
      ++ [
        "/data  ${subnets.tailscale}(rw,sync,no_subtree_check,no_root_squash,insecure)"
        "/data  ${subnets.media}(ro,sync,no_subtree_check,root_squash,insecure)"
      ]
    );
  };

  # NFSv4-only: v3 needs rpcbind/statd/MOUNT, all clients mount with nfsvers=4.2.
  services.nfs.settings.nfsd.vers3 = false;
  services.rpcbind.enable = lib.mkForce false;
  systemd.services.rpc-statd.enable = false;
  systemd.services.rpc-statd-notify.enable = false;
  # mountd still serves nfsd's export upcalls, just no MOUNT listeners.
  systemd.services.nfs-mountd.serviceConfig.ExecStart = [
    ""
    "${pkgs.nfs-utils}/bin/rpc.mountd --no-tcp --no-udp"
  ];

  # gvfs trash support on NFS: XDG trash spec requires $topdir/.Trash-<uid>.
  # 1000 is the first regular-user uid NixOS allocates (config.my.defaults.user
  # has no pinned uid, so config.users.users.<name>.uid is null at eval time
  # and can't be used here).
  systemd.tmpfiles.rules = [
    "d /data/.Trash-1000 0700 ${config.my.defaults.user} users -"
  ];

  networking.firewall = {
    allowedTCPPorts = [2049];
    allowedUDPPorts = [2049];
    interfaces.tailscale0.allowedTCPPorts = [2049];
  };
}
