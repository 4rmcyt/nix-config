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
  # Lets gamemoded's hooks drive scx_loader over DBus without a polkit password prompt.
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.scx.loader.manage-schedulers" && subject.active && subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # GameConqueror/scanmem attach to wine/proton games via ptrace; default yama
  # scope (1) blocks tracing non-descendant processes.
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 0;

  programs.gamemode = {
    enable = true;
    settings = {
      # Daily-driver scheduler/rationale lives in
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
        # index 2 (a prior guess) doesn't exist; only NVIDIA GPU is nvidia-smi index 0.
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

  # capSysNice MUST stay false: with it, the gamescope wrapper leaks ambient caps into
  # children and pressure-vessel's bwrap aborts ("Unexpected capabilities but not
  # setuid"), failing every Proton/umu game launch.
  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };

  # Steam's client UI is XWayland and doesn't read the compositor's output scale
  # (scale:2 monitors, modules/WM/mango/monitors/desktop.nix) — Valve's own workaround.
  environment.sessionVariables.STEAM_FORCE_DESKTOPUI_SCALING = "2.0";

  environment.systemPackages = with pkgs; [
    wine
    winetricks

    gamemode
    # gamescope — installed via programs.gamescope above
    # mangohud
    # vesktop
    lutris
    protonup-qt
    pcsx2
    shadps4-qtlauncher
    vulkan-tools

    jstest-gtk

    # Needs kernel.yama.ptrace_scope = 0 (set above).
    scanmem

    # gamemode's nvidia GPU-optimisation path shells out to nvidia-settings
    config.boot.kernelPackages.nvidiaPackages.stable.settings
  ];

  hardware.graphics.enable32Bit = true;

  boot.kernelModules = ["hid_nintendo"];
  hardware.steam-hardware.enable = true;

  # xpadneo replaces in-kernel xpad for proper rumble/trigger/battery support over Bluetooth.
  boot.extraModulePackages = [config.boot.kernelPackages.xpadneo];
  boot.blacklistedKernelModules = ["xpad"];

  services.udev.extraRules = ''
    KERNEL=="card[0-9]*", SUBSYSTEM=="drm", GROUP="video", MODE="0664"
    KERNEL=="controlD[0-9]*", SUBSYSTEM=="drm", GROUP="video", MODE="0664"

    KERNEL=="nvidia*", GROUP="video", MODE="0664"
    KERNEL=="nvidiactl", GROUP="video", MODE="0664"
    KERNEL=="nvidia-modeset", GROUP="video", MODE="0664"
    KERNEL=="nvidia-uvm", GROUP="video", MODE="0664"
  '';

  # User group memberships (gamemode, video) live in modules/users/zeev/default.nix.
}
