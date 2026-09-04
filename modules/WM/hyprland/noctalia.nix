{pkgs, ...}: {
  programs.noctalia = {
    enable = true;
    # spawn-at-startup configured in startup.nix; systemd service not used
    settings = {};
  };

  # playerctl for media key bindings
  home.packages = [pkgs.playerctl];
}
