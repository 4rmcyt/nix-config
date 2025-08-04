{
  config,
  pkgs,
  lib,
  ...
}:

{
  sops.secrets = {
    # --- Microbin Secrets ---
    microbin_admin_password = {
      sopsFile = ../../../secrets/microbin.yaml;
      key = "microbin_admin_password";
      owner = config.users.users.microbin.name;
      group = config.users.groups.microbin.name;
      mode = "0400";
    };
  };

  users.users.microbin = {
    isSystemUser = true;
    group = "microbin";
    extraGroups = [ "users" ];
  };
  users.groups.microbin = { };

  networking.firewall.allowedTCPPorts = [
    8084 # Microbin
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."microbin.example.com" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/example.com/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/example.com/key.pem";
      locations."/" = {
        proxyPass = "http://localhost:8084";
        proxyWebsockets = true;
      };
    };
  };

  environment.systemPackages = [ pkgs.microbin ];

  services.microbin = {
    enable = true;
    settings = {
      MICROBIN_BIND = "127.0.0.1";
      MICROBIN_PORT = "8084";
      MICROBIN_PUBLIC_PATH = "https://microbin.example.com";
      MICROBIN_EDITABLE = true;
      MICROBIN_HIGHLIGHTSYNTAX = true;
      MICROBIN_GC_DAYS = 30;
      MICROBIN_TITLE = "Homeserver microbin";
      MICROBIN_SHORT_PATH = "https://p.in";
      MICROBIN_QR = true;
      MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
      MICROBIN_ENCRYPTION_SERVER_SIDE = true;
      MICROBIN_BASIC_AUTH_USERNAME = "microbin";
      MICROBIN_BASIC_AUTH_PASSWORD = "microbin";
      MICROBIN_ADMIN_USERNAME = "admin";
      MICROBIN_ADMIN_PASSWORD = config.sops.secrets.microbin_admin_password.path;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/microbin 0755 microbin microbin -"
    "d /var/lib/microbin/data 0755 microbin microbin -"
    "d /var/lib/microbin/config 0755 microbin microbin -"
    "d /var/lib/microbin/logs 0755 microbin microbin -"
  ];
}
