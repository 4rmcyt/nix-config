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

  # Enable gamemode service properly
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        ioprio = 7;
        inhibit_screensaver = 1;
      };
      
      # Remove GPU optimizations that are causing issues
      gpu = {
        apply_gpu_optimisations = "reject-responsibility"; # Changed from accept-responsibility
        # Remove nvidia_performance_level as it's not supported
      };
      
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };

  # Gaming packages
  environment.systemPackages =
    with pkgs;
    [
      # Gaming utilities
      # lutris # TODO: Re-enable when allegro CMake issue is fixed
      heroic
      bottles
      wine
      winetricks

      # Performance tools
      gamescope
      mangohud
      # gamemode is now handled by programs.gamemode above
    ]
    ++ lib.optionals (inputs ? nix-gaming) [
      inputs.nix-gaming.packages.${pkgs.system}.wine-ge
    ];

  # Enable 32-bit support for games
  hardware.graphics.enable32Bit = true;

  # Add user to gamemode group
  users.groups.gamemode.members = [ "zeev" ];
}
