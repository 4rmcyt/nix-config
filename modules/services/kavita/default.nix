{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    # --- Kavita Secrets ---
    kavita_token_key_file = {
      sopsFile = ../../../secrets/kavita.yaml;
      key = "tokenKeyFile";
      owner = config.users.users.kavita.name;
      group = config.users.groups.kavita.name;
      mode = "0400";
    };
  };

  users.users.kavita = {
    isSystemUser = true;
    group = "kavita";
    extraGroups = [
      "users"
      "media"
      "kavita"
    ];
  };
  users.groups.kavita = {};

  networking.firewall.allowedTCPPorts = [
    5000 # Kavita
  ];

  # Nginx configuration managed in modules/security/keycloak/nginx-auth.nix

  environment.systemPackages = [pkgs.kavita];

  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets.kavita_token_key_file.path;
    settings = {
      UI = {
        Theme = "dracula";
      };
      Libraries = [
        {Path = "/data/media/comics";}
        {Path = "/data/media/manga";}
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kavita 0755 kavita kavita -"
    "d /var/lib/kavita/libraries 0755 kavita kavita -"
    "d /var/lib/kavita/config 0755 kavita kavita -"
    "d /var/lib/kavita/logs 0755 kavita kavita -"
  ];
}
