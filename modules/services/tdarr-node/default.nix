{
  config,
  pkgs,
  ...
}: let
  homeserverIP = config.my.defaults.homeserver_lan;
in {
  users = {
    users.tdarr = {
      isSystemUser = true;
      group = "tdarr";
    };
    groups.tdarr = {};
  };

  networking.firewall.allowedTCPPorts = [
    8267 # Tdarr Node
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/tdarr-node 0755 tdarr tdarr -"
    "d /var/lib/tdarr-node/configs 0755 tdarr tdarr -"
    "d /var/lib/tdarr-node/logs 0755 tdarr tdarr -"
    "d /var/lib/tdarr-node/assets/app/plugins 0755 tdarr tdarr -"
  ];

  systemd.services.tdarr-node = {
    description = "Tdarr Node (desktop worker)";
    wantedBy = ["multi-user.target"];
    after = ["network.target" "network-online.target"];

    environment = {
      rootDataPath = "/var/lib/tdarr-node";
    };

    # Pre-seed node config with homeserver address on first run
    preStart = let
      cfg = "/var/lib/tdarr-node/configs/Tdarr_Node_Config.json";
    in ''
      if [ ! -f "${cfg}" ] || ! ${pkgs.gnugrep}/bin/grep -q '"serverIP"' "${cfg}"; then
        printf '{"nodeID":"desktop-node","nodeIP":"auto","nodePort":"8267","serverIP":"%s","serverPort":"8266"}' "${homeserverIP}" > "${cfg}"
      fi
    '';

    serviceConfig = {
      Type = "simple";
      User = "tdarr";
      Group = "tdarr";
      ExecStart = "${pkgs.tdarr-node}/bin/tdarr-node";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
