{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    platformOptimizations.enable = true;
  };
  

  # GameMode
  programs.gamemode = {
    enable = lib.mkForce true;  # Use mkForce to resolve the conflict
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };


  # Gaming packages
  environment.systemPackages =
    with pkgs;
    [
      # Gaming utilities
      lutris
      heroic
      bottles
      wine
      winetricks

      # Performance tools
      inputs.chaotic.packages.${pkgs.system}.gamescope or gamescope
      mangohud
      gamemode
    ]
    ++ lib.optionals (inputs ? nix-gaming) [
      inputs.nix-gaming.packages.${pkgs.system}.wine-ge
    ];

  # Enable 32-bit support for games
  hardware.graphics.enable32Bit = true;

  # Gamemode settings
  environment.etc."gamemode.ini".text = ''
    [general]
    renice=10
    ioprio=7
    inhibit_screensaver=1

    [gpu]
    apply_gpu_optimisations=accept-responsibility
    gpu_device=0
    nvidia_performance_level=high

    [custom]
    start=${pkgs.libnotify}/bin/notify-send "GameMode started"
    end=${pkgs.libnotify}/bin/notify-send "GameMode ended"
  '';
}
