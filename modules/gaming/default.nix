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

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        ioprio = 7;
        inhibit_screensaver = 1;
      };

      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        nvidia_performance_level = "high";
        # gpu_device = 0; # Let gamemode auto-detect the GPU

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
        gamemode
      ]
      ++ lib.optionals (inputs ? nix-gaming) [
        inputs.nix-gaming.packages.${pkgs.system}.wine-ge
      ];

    # Enable 32-bit support for games
    hardware.graphics.enable32Bit = true;
  };
}
