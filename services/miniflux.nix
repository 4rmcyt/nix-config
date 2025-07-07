{ config, pkgs, ... }:

let

  minifluxCredentials = pkgs.writeText "miniflux-credentials" ''
    admin:$(cat ${config.sops.secrets.miniflux_admin_password.path})
  '';
in
{
  sops.secrets.miniflux_admin_password = {};

  services.miniflux = {
    enable = true;
    CREATE_ADMIN = 1;
    adminCredentialsFile = minifluxCredentials;
    config = {
      LISTEN_ADDR = "127.0.0.1:8086";
    };
  };
}
