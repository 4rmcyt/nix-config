{ pkgs, ... }:
{
  imports = [
    ./external/thunderbird.nix
  ];

  # Thunderbird
  programs.thunderbird-extra = {
    enable = true;
    profiles = [ "${config.home.username}" ];
    settings = id: {
      "mail.server.server_${id}.authMethod" = 10;
      "mail.smtpserver.smtp_${id}.authMethod" = 10;
    };
  };

  # Proton Mail Bridge
  home.packages = with pkgs; [
    protonmail-bridge
  ];

  systemd.user.services.protonmail-bridge = {
    Unit = {
      Description = "Start Proton Mail Bridge";
      PartOf = "graphical-session.target";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      Environment = [
        "XDG_CONFIG_HOME=/home/marc/Services/protonmail-bridge/config"
        "XDG_CACHE_HOME=/home/marc/Services/protonmail-bridge/cache"
        "XDG_DATA_HOME=/home/marc/Services/protonmail-bridge/data"
      ];
      ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
      Restart = "on-failure";
    };
  };
}
