_: {
  services.rpcbind.enable = true;

  fileSystems."/mnt/media" = {
    device = "homeserver:/data/media";
    fsType = "nfs";
    options = [
      "vers=4.2"
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
