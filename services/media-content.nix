
{ config, pkgs, lib, ... }:

{
  users.users.fileserver = {
    isSystemUser = true;
    group = "fileserver";
    home = "/srv/files";
  };

  users.groups.fileserver = {};

  sops.secrets.miniflux_admin_password = { };

  # Miniflux RSS reader - Fix: Use correct port 8086
  services.miniflux = {
    enable = true;
    config = {
      LISTEN_ADDR = "127.0.0.1:8086";  # Changed from 8084 to 8086
      ADMIN_USERNAME = "admin";
      ADMIN_PASSWORD = "$(cat ${config.sops.secrets.miniflux_admin_password.path})";
      BASE_URL = "https://rss.example.com";
    };
    adminCredentialsFile = config.sops.secrets.miniflux_admin_password.path;
  };

  # Simple HTTP file server - Fix: Use different port
  systemd.services.simple-fileserver = {
    enable = true;
    description = "Simple HTTP file server";
    after = [ "network.target" "systemd-tmpfiles-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python -m http.server 8087 --bind 127.0.0.1";  # Changed from 8084 to 8087
      Restart = "always";
      User = "fileserver";
      Group = "fileserver";
      WorkingDirectory = "/srv/files";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/files 0755 fileserver fileserver -"
  ];

  # REMOVED: Firewall ports (now handled centrally in networking.nix)
}