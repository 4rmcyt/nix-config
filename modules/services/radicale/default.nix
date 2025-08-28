{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.radicale_users = {
    sopsFile = ../../../secrets/radicale_users.txt;
    owner = config.users.users.radicale.name;
    group = config.users.groups.radicale.name;
    mode = "0440";
    format = "binary";
  };

  users.users.radicale = {
    isSystemUser = true;
    group = "radicale";
    extraGroups = [ "users" ];
  };
  users.groups.radicale = { };

  networking.firewall.allowedTCPPorts = [ 5232 ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."cal.example.com" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/example.com/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/example.com/key.pem";
      locations."/" = {
        proxyPass = "http://localhost:5232";
        proxyWebsockets = true;
      };
    };
  };
  environment.systemPackages = [ pkgs.radicale ];
  services.radicale = {
    enable = true;
    settings = {
      server = {
        hosts = [ "127.0.0.1:5232" ];
      };

      auth = {
        type = "htpasswd";
        htpasswd_filename = config.sops.secrets.radicale_users.path;
        htpasswd_encryption = "bcrypt";
      };

      storage = {
        filesystem_folder = "/var/lib/radicale/collections";
      };

      web = { };

      logging = {
        level = "info";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/radicale/collections 0750 radicale radicale -"
  ];
}
