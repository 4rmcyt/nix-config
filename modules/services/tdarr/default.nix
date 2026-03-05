{
  pkgs,
  ...
}: {
  users = {
    users.tdarr = {
      isSystemUser = true;
      group = "tdarr";
      extraGroups = [
        "media"
        "users"
      ];
    };
    groups.tdarr = {};
  };

  networking.firewall.allowedTCPPorts = [
    8265 # Tdarr Web UI
    8266 # Tdarr Server
    8267 # Tdarr Node
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/tdarr 0755 tdarr tdarr -"
    "d /var/lib/tdarr/server 0755 tdarr tdarr -"
    "d /var/lib/tdarr/server/configs 0755 tdarr tdarr -"
    "d /var/lib/tdarr/server/logs 0755 tdarr tdarr -"
    "d /var/lib/tdarr/node 0755 tdarr tdarr -"
    "d /var/lib/tdarr/node/configs 0755 tdarr tdarr -"
    "d /var/lib/tdarr/node/logs 0755 tdarr tdarr -"
    "d /var/lib/tdarr/node/assets 0755 tdarr tdarr -"
    "d /var/lib/tdarr/node/assets/app 0755 tdarr tdarr -"
    "d /var/lib/tdarr/node/assets/app/plugins 0755 tdarr tdarr -"
    "Z /var/lib/tdarr/node - tdarr tdarr -"
    "d /var/lib/tdarr/cache 0775 tdarr media -"
  ];

  # pkgs.tdarr is a symlink-join providing both tdarr-server and tdarr-node binaries
  systemd.services = {
    tdarr-server = {
      description = "Tdarr Server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      environment = {
        # Override the default XDG_DATA_HOME path used by the wrapper
        rootDataPath = "/var/lib/tdarr/server";
      };

      serviceConfig = {
        Type = "simple";
        User = "tdarr";
        Group = "tdarr";
        ExecStart = "${pkgs.tdarr}/bin/tdarr-server";
        Restart = "on-failure";
        RestartSec = "5s";
        BindPaths = [
          "/data/media"
          "/var/lib/tdarr/cache"
        ];
      };
    };

    tdarr-node = {
      description = "Tdarr Node (homeserver local worker)";
      wantedBy = ["multi-user.target"];
      after = ["network.target" "tdarr-server.service"];
      requires = ["tdarr-server.service"];

      environment = {
        rootDataPath = "/var/lib/tdarr/node";
      };

      serviceConfig = {
        Type = "simple";
        User = "tdarr";
        Group = "tdarr";
        ExecStart = "${pkgs.tdarr}/bin/tdarr-node";
        Restart = "on-failure";
        RestartSec = "5s";
        BindPaths = [
          "/data/media"
          "/var/lib/tdarr/cache"
        ];
      };
    };
  };
}
