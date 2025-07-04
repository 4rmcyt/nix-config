{ config, pkgs, ... }:

let
  nextcloudWebDir = "/var/www/nextcloud";
in
{
  users.users.nextcloud = {
    isSystemUser = true;
    home = nextcloudWebDir;
    group = "nextcloud";
  };
  users.groups.nextcloud = {};

  # Download Nextcloud (one-time, or manage manually)
  system.activationScripts.nextcloud = ''
    mkdir -p ${nextcloudWebDir}
    if [ ! -e ${nextcloudWebDir}/index.php ]; then
      cd /tmp
      curl -L https://download.nextcloud.com/server/releases/latest.tar.bz2 -o nextcloud.tar.bz2
      tar -xjf nextcloud.tar.bz2
      rm -rf ${nextcloudWebDir}/*
      mv nextcloud/* ${nextcloudWebDir}/
      chown -R nextcloud:nextcloud ${nextcloudWebDir}
      rm -rf nextcloud nextcloud.tar.bz2
    fi
  '';
  
  services.phpfpm.enable = true;
  services.phpfpm.pools.nextcloud = {
    user = "nextcloud";
    group = "nextcloud";
    phpPackage = pkgs.php;
    settings = {
      "listen" = "/run/phpfpm-nextcloud.sock";
      "listen.owner" = "nextcloud";
      "listen.group" = "nextcloud";
      "listen.mode" = "0660";
      "pm" = "dynamic";
      "pm.max_children" = 12;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 6;
    };
  };

  environment.systemPackages = with pkgs; [
    php
    curl
    zip
    gd
    zlib
    openssl
    postgresql
    redis
    imagemagick
  ];

  systemd.tmpfiles.rules = [
    "d ${nextcloudWebDir} 0755 nextcloud nextcloud - -"
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}