{
  lib,
  pkgs,
  inputs,
  config,
  ...
}: {
  # Programs
  programs.gamemode = {
    enable = true;
    settings = {
      custom = {
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
      };

      general = {
        inhibit_screensaver = 1;
        ioprio = 7;
        renice = 10;
      };

      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 2;
      };
    };
  };

  programs.steam = {
    dedicatedServer.openFirewall = true;
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
  };

  # Gaming packages
  environment.systemPackages = with pkgs;
    [
      # Gaming utilities
      # lutris # Disabled due to allegro CMake compatibility issue in current nixpkgs
      # Re-enable when fixed: https://github.com/NixOS/nixpkgs/issues/...
      bottles
      heroic
      wine
      winetricks

      # Performance tools
      gamemode
      gamescope
      mangohud
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

  # Ensure the primary user is in the video group
  users.users.${config.my.defaults.user}.extraGroups = [
    "gamemode"
    "pipewire"
    "video"
  ];
}
