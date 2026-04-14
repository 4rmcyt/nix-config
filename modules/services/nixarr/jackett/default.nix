_: {
  services.jackett = {
    enable = true;
    port = 9117;
    openFirewall = false;
    dataDir = "/data/media/.state/nixarr/jackett";
    user = "jackett";
    group = "media";
  };

  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/jackett 775 jackett media -"
  ];
}
