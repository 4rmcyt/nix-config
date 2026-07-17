{config, ...}: let
  inherit (config.my.defaults) user;
in {
  # Desktop journald overrides — more storage and longer retention than base defaults
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    SystemMaxFileSize=100M
    MaxRetentionSec=1month
  '';

  # Ensure hyprland log directory exists before login
  systemd.tmpfiles.rules = [
    "d /home/${user}/.local/state/hyprland 0755 ${user} users - -"
  ];
}
