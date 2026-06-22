{pkgs, ...}: {
  # Steam needs system fonts to render UI text (especially non-Latin scripts)
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
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
    gamescopeSession.enable = false;
    remotePlay.openFirewall = true;
  };

  # Gaming packages
  environment.systemPackages = with pkgs; [
    # heroic
    wine
    winetricks

    # Performance tools
    gamemode
    gamescope
    # mangohud
    # vesktop
    # lutris
    # protonup-qt
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

  # Note: User group memberships (gamemode, video) are defined in modules/users/zeev/default.nix
  # to avoid duplication. Keeping this comment for reference.
}
