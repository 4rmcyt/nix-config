{pkgs, ...}: {
  programs.noctalia-shell = {
    enable = true;
    # exec-once configured in startup.nix; systemd service not used

    settings = {};
  };

  # playerctl for media key bindings
  home.packages = [pkgs.playerctl];
}
