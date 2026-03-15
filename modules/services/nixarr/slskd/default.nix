{
  config,
  lib,
  ...
}: let
  slskdPort = 5030;
in {
  sops.secrets.slskd_env = {
    sopsFile = ../../../secrets/slskd.env;
    format = "dotenv";
    owner = config.services.slskd.user;
    mode = "0400";
  };

  services.slskd = {
    enable = true;
    environmentFile = config.sops.secrets.slskd_env.path;
    settings = {
      web.port = slskdPort;
      shares.directories = ["/data/media/music"];
      downloads = {
        directory = "/data/Downloads/slskd";
        incomplete_directory = "/data/Downloads/slskd/incomplete";
      };
      directories = {
        incomplete = "/data/Downloads/slskd/incomplete";
        downloads = "/data/Downloads/slskd";
      };
    };
  };

  systemd.services.slskd.serviceConfig = {
    UMask = lib.mkDefault "0002";
    BindPaths = [
      "/data/Downloads"
      "/data/media/music"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /data/Downloads/slskd 775 ${config.services.slskd.user} media -"
    "d /data/Downloads/slskd/incomplete 775 ${config.services.slskd.user} media -"
  ];

  users.users.${config.services.slskd.user}.extraGroups = ["media"];

  networking.firewall.allowedTCPPorts = [slskdPort];
}
