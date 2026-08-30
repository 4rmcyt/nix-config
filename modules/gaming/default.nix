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
  # Let gamemoded's custom hooks drive scx_loader over DBus without a polkit
  # password prompt. gamemoded runs in the user session (active + wheel).
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.scx.loader.manage-schedulers" && subject.active && subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Memory scanners (GameConqueror/scanmem below) attach to wine/proton games
  # via ptrace; the default yama scope (1) blocks tracing non-descendant
  # processes. Games box only — plain single-player value editing.
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 0;

  # Programs
  programs.gamemode = {
    enable = true;
    settings = {
      # On game launch, hot-swap the CPU scheduler to scx_bpfland in "gaming"
      # mode (-m all); revert to scx_lavd auto on exit. The daily-driver
      # scheduler and the rationale live in
      # hosts/nixos/desktop/hardware-configuration.nix (services.scx-loader).
      custom = {
        start = toString (pkgs.writeShellScript "gamemode-start" ''
          ${pkgs.scx-loader}/bin/scxctl switch -s scx_bpfland -m gaming || true
          ${pkgs.libnotify}/bin/notify-send 'GameMode started' 'scheduler → scx_bpfland (gaming)'
        '');
        end = toString (pkgs.writeShellScript "gamemode-end" ''
          ${pkgs.scx-loader}/bin/scxctl switch -s scx_lavd -m auto || true
          ${pkgs.libnotify}/bin/notify-send 'GameMode ended' 'scheduler → scx_lavd (auto)'
        '');
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

  # BBLauncher's "Manage Builds" downloads shadPS4 as a raw AppImage and
  # execs it directly (unlike bb-launcher itself, which is nix-wrapped at
  # build time) — without this it fails to mount via FUSE.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.steam = {
    dedicatedServer.openFirewall = true;
    enable = true;
    gamescopeSession.enable = false;
    remotePlay.openFirewall = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
  };

  # gamescope as a nested micro-compositor (run per-game via Lutris/Steam
  # launch options, not as a session). capSysNice lets it set RT priority so
  # the nested game gets scheduling headroom instead of logging "Failed to
  # get nice level" and stuttering. Fixes the XWayland scale:2 blur: the game
  # renders at e.g. 1920x1080 and gamescope integer-scales x2 to the 4K panel.
  programs.gamescope = {
    enable = true;
    capSysNice = true;
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

    # Memory scanner/editor (GameConqueror GUI) — single-player value editing.
    # Needs kernel.yama.ptrace_scope = 0 (set above).
    scanmem

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
