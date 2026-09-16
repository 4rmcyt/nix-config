{pkgs, ...}: {
  programs.noctalia = {
    enable = true;
    # spawn-at-startup configured in startup.nix; systemd service not used
    settings = {};
  };

  home.packages = [pkgs.playerctl];
}
