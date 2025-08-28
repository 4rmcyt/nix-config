{ pkgs, ... }:
{
  glade = {
    apps.enable = false;

    programs = {
      enable = true;
    };

    tooling.enable = true;
  };

  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
  };

  wsl = {
    enable = true;
    defaultUser = "zeev";
    startMenuLaunchers = true;

    wslConf.network.hostname = "ZephyrusG14";
  };
}