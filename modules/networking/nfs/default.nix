_: {
  services.nfs.server = {
    enable = true;
    nproc = 8;
    exports = ''
      /data  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash,insecure)
      /data  100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,insecure)
      /data  192.168.30.0/24(ro,sync,no_subtree_check,root_squash,insecure)
    '';
  };

  # gvfs trash support on NFS: XDG trash spec requires $topdir/.Trash-<uid>
  systemd.tmpfiles.rules = [
    "d /data/.Trash-1000 0700 zeev users -"
  ];

  networking.firewall = {
    allowedTCPPorts = [2049];
    allowedUDPPorts = [2049];
    interfaces.tailscale0.allowedTCPPorts = [2049];
  };
}
