_: {
  services.rpcbind.enable = true;
  boot.supportedFilesystems = ["nfs"];

  fileSystems."/mnt/media" = {
    device = "homeserver:/data";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10"
      "x-systemd.requires=network-online.target"
      "nofail"
      "_netdev"
    ];
  };
}
