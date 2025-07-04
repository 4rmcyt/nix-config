{ config, pkgs, lib, ... }:

{
  sops.secrets.miniflux_admin_password = { };

  # Miniflux RSS reader
  services.miniflux = {
    enable = true;
    config = {
      LISTEN_ADDR = "127.0.0.1:8086";
      ADMIN_USERNAME = "admin";
      ADMIN_PASSWORD = "$(cat ${config.sops.secrets.miniflux_admin_password.path})";
      BASE_URL = "https://rss.labhome.work";
    };
    adminCredentialsFile = config.sops.secrets.miniflux_admin_password.path;
  };

  # Remove PostgreSQL configuration - handled by database.nix

  # Simple HTTP file server
  systemd.services.simple-fileserver = {
    enable = true;
    description = "Simple HTTP file server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python -m http.server 8084 --bind 127.0.0.1";
      Restart = "always";
      User = "fileserver";
      Group = "fileserver";
      DynamicUser = true;
      WorkingDirectory = "/home/zeev/fileserver";
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/zeev/fileserver 0755 fileserver fileserver -"
  ];

  networking.firewall.allowedTCPPorts = [ 8083 8084 ];
}