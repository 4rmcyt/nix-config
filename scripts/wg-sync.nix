{ config, pkgs, lib, ... }:

{

  systemd.tmpfiles.rules = [
    "d /data/.secret 0700 zeev media -"
  ];

 
  systemd.services.copy-wireguard-config = {
    description = "Copy WireGuard configuration to persistent storage";

    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true; 

      ExecStart = ''
        ${pkgs.coreutils}/bin/install -m 600 -o zeev -g media \
          ${./../secrets/wg.conf} \
          /data/.secret/wg.conf
      '';
    };
    unitConfig.ConditionPathExists = "!/data/.secret/wg.conf";
  };
}
