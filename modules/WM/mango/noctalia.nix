{pkgs, ...}: {
  programs.noctalia = {
    enable = true;
    # autostart_sh spawns `noctalia` directly (see startup.nix); systemd
    # service not used.

    settings = {};
  };

  home.packages = [pkgs.playerctl];
}
