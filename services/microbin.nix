{
  config,
  pkgs,
  lib,
  ...
}:

{ 
  environment.systemPackages = [ pkgs.microbin ];

  services.microbin = {
    enable = true;
    settings = {
      MICROBIN_BIND = "127.0.0.1";
      MICROBIN_PORT = "8084";
      MICROBIN_PUBLIC_PATH = "https://paste.labhome.work";
      MICROBIN_EDITABLE = true;
      MICROBIN_HIGHLIGHTSYNTAX = true;
      MICROBIN_GC_DAYS = 30;
      MICROBIN_TITLE = "Homeserver Pastebin";
      MICROBIN_SHORT_PATH = "https://p.in";
      MICROBIN_QR = true;
      MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
      MICROBIN_ENCRYPTION_SERVER_SIDE = true;
      MICROBIN_BASIC_AUTH_USERNAME = "microbin";
      MICROBIN_BASIC_AUTH_PASSWORD = config.sops.secrets.microbin_user_password.path;
      MICROBIN_ADMIN_USERNAME = "admin";
      MICROBIN_ADMIN_PASSWORD = config.sops.secrets.microbin_admin_password.path;
    };
  };

  users.users.microbin = {
    isSystemUser = true;
    group = "microbin";
    extraGroups = [ "users"];
  };
  users.groups.microbin = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/microbin 0755 microbin microbin -"
    "d /var/lib/microbin/data 0755 microbin microbin -"
    "d /var/lib/microbin/config 0755 microbin microbin -"
    "d /var/lib/microbin/logs 0755 microbin microbin -"
  ];
}
