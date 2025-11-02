{
  lib,
  pkgs,
  inputs,
  ...
}: {
  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
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
        gpu_device = 2;
      };

      # Move custom section to top level (outside of gpu)
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };

  # Gaming packages
  environment.systemPackages = with pkgs;
    [
      # Gaming utilities
      # lutris # Disabled due to allegro CMake compatibility issue in current nixpkgs
      # Re-enable when fixed: https://github.com/NixOS/nixpkgs/issues/...
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
      inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-ge
    ];

  # Enable 32-bit support for games
  hardware.graphics.enable32Bit = true;

  # Add udev rules for gamemode GPU access
  services.udev.extraRules = ''
    # Allow gamemode to access GPU vendor information
    KERNEL=="card[0-9]*", SUBSYSTEM=="drm", GROUP="video", MODE="0664"
    KERNEL=="controlD[0-9]*", SUBSYSTEM=="drm", GROUP="video", MODE="0664"

    # NVIDIA specific rules
    KERNEL=="nvidia*", GROUP="video", MODE="0664"
    KERNEL=="nvidiactl", GROUP="video", MODE="0664"
    KERNEL=="nvidia-modeset", GROUP="video", MODE="0664"
    KERNEL=="nvidia-uvm", GROUP="video", MODE="0664"
  '';

  # Ensure your user is in the video group
  users.users.zeev.extraGroups = [
    "video"
    "gamemode"
    "pipewire"
  ];
}
