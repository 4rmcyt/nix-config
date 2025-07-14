{ config, pkgs, ... }:

{
  services.radicale = {
    enable = true;
    settings = {
      server = {
        hosts = [ "127.0.0.1:5232" ];
      };
      
      auth = {
        type = "htpasswd";
        htpasswd_filename = "/var/lib/radicale/users";
        htpasswd_encryption = "bcrypt";
      };
      
      storage = {
        filesystem_folder = "/var/lib/radicale/collections";
      };
      
      web = {
        # base_prefix = "/";
      };
      
      logging = {
        level = "info";
      };
    };
  };

  # Create radicale user and directories
  systemd.tmpfiles.rules = [
    "d /var/lib/radicale 0755 radicale radicale -"
    "d /var/lib/radicale/collections 0755 radicale radicale -"
  ];

  # Create default user file if it doesn't exist
  systemd.services.radicale-setup = {
    description = "Setup Radicale users";
    wantedBy = [ "radicale.service" ];
    before = [ "radicale.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "radicale";
      Group = "radicale";
    };
    script = ''
      if [ ! -f /var/lib/radicale/users ]; then
        # Create default user (username: admin, password: admin)
        # Change this after first login!
        echo 'admin:$2b$12$AhaxvKmfHkIWmVVgTKL2NOa9QrGgMuqf5fHyV8.SQzTLjmUKBiXPa' > /var/lib/radicale/users
        chown radicale:radicale /var/lib/radicale/users
        chmod 600 /var/lib/radicale/users
      fi
    '';
  };
}