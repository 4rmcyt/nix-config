_: {
  services.nfs.server = {
    enable = true;
    nfsd.nproc = 8;
    exports = ''
      /data/media  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=0,crossmnt)
      /data/media  100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=0,crossmnt)
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [2049];
    allowedUDPPorts = [2049];
    interfaces.tailscale0.allowedTCPPorts = [2049];
  };
}
