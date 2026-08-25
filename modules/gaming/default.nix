{
  config,
  pkgs,
  ...
}: {
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
        # Only one NVIDIA GPU present (RTX 3050, nvidia-smi index 0) plus an
        # AMD iGPU gamemode doesn't touch — index 2 didn't exist, hence
        # "Failed to find Nvidia GPU with expected index!" every launch.
        gpu_device = 0;
      };
    };
  };

  programs.steam = {
    dedicatedServer.openFirewall = true;
    enable = true;
    gamescopeSession.enable = false;
    remotePlay.openFirewall = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
  };

  # Steam's client UI is an XWayland app and doesn't read the compositor's
  # output scale, so on the scale:2 monitors (modules/WM/mango/monitors/
  # desktop.nix) it renders at 1x and gets stretched — blurry. This is
  # Valve's own documented workaround.
  environment.sessionVariables.STEAM_FORCE_DESKTOPUI_SCALING = "2.0";

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
    lutris
    protonup-qt

    # Controller testing
    jstest-gtk

    # gamemode's nvidia GPU-optimisation path shells out to nvidia-settings
    config.boot.kernelPackages.nvidiaPackages.stable.settings
  ];

  # Enable 32-bit support for games
  hardware.graphics.enable32Bit = true;

  # Nintendo Switch Pro Controller support
  boot.kernelModules = ["hid_nintendo"];
  hardware.steam-hardware.enable = true;

  # Xbox controller support over Bluetooth (Elite/Pro included): xpadneo
  # replaces the in-kernel xpad driver for proper rumble, trigger/paddle
  # button, and battery-level support.
  boot.extraModulePackages = [config.boot.kernelPackages.xpadneo];
  boot.blacklistedKernelModules = ["xpad"];

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
