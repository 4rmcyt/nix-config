{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.my.network) subnets;

  # No PrivateNetwork/ProcSubset: /proc/net/rpc cache channels are per-netns and under /proc.
  nfsSandbox = {
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    PrivateTmp = true;
    ProtectHome = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    SystemCallArchitectures = "native";
  };
in {
  services.nfs.server = {
    enable = true;
    nproc = 8;
    # rw only to the trusted VLAN: no tailnet (gcp-relay/phones) and no ISP-router subnet.
    exports = lib.concatStringsSep "\n" [
      "/data  ${subnets.trusted}(rw,sync,no_subtree_check,no_root_squash,insecure)"
      "/data  ${subnets.media}(ro,sync,no_subtree_check,root_squash,insecure)"
    ];
  };

  # NFSv4-only: v3 needs rpcbind/statd/MOUNT, all clients mount with nfsvers=4.2.
  services.nfs.settings.nfsd.vers3 = false;
  services.rpcbind.enable = lib.mkForce false;
  systemd.services.rpc-statd.enable = false;
  systemd.services.rpc-statd-notify.enable = false;
  systemd.services = {
    # Only writes /proc/net/rpc (not /proc/fs), so ProtectKernelTunables is safe here.
    nfs-idmapd.serviceConfig =
      nfsSandbox
      // {
        ReadWritePaths = ["/var/lib/nfs"];
        PrivateDevices = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = ["AF_UNIX"];
      };

    # No PrivateDevices/ProtectClock: blkid fsid/uuid probing needs /dev, else client handles go stale.
    nfs-mountd.serviceConfig =
      nfsSandbox
      // {
        # mountd still serves nfsd's export upcalls, just no MOUNT listeners.
        ExecStart = [
          ""
          "${pkgs.nfs-utils}/bin/rpc.mountd --no-tcp --no-udp"
        ];
        RestrictAddressFamilies = ["AF_UNIX" "AF_NETLINK" "AF_INET" "AF_INET6"];
        # Kernel resolves export paths in mountd's mount ns; RO there = EROFS for every client.
        ReadWritePaths = ["/data"];
      };

    # No ProtectKernelTunables: writes /proc/fs/nfsd/v4_end_grace.
    nfsdcld.serviceConfig =
      nfsSandbox
      // {
        ReadWritePaths = ["/var/lib/nfs"];
        PrivateDevices = true;
        ProtectClock = true;
        RestrictAddressFamilies = ["AF_UNIX"];
      };
  };

  # gvfs trash support on NFS: XDG trash spec requires $topdir/.Trash-<uid>.
  # 1000 is the first regular-user uid NixOS allocates (config.my.defaults.user
  # has no pinned uid, so config.users.users.<name>.uid is null at eval time
  # and can't be used here).
  systemd.tmpfiles.rules = [
    "d /data/.Trash-1000 0700 ${config.my.defaults.user} users -"
  ];

  # NFSv4 is TCP-only.
  networking.firewall.allowedTCPPorts = [2049];
}
