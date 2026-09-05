{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules/TUI/ai-tools/llama-cpp/cpu.nix

    inputs.private.homeModules.thunderbird
    ../../modules/GUI/IDE/vscode
    ../../modules/TUI/tmux
    ../../modules/TUI/starship
    ../../modules/WM/niri
    ../../modules/WM/niri/monitors/matebook.nix
  ];
  home = {
    packages = with pkgs; [
      bat
      brightnessctl
      davfs2
      materialgram
      pam_u2f
      pcsc-tools
      ryzen-monitor-ng
      signal-desktop
      slack
      yubioath-flutter
    ];

    sessionVariables = {
      # Graphics & Display (AMD) — Wayland vars provided by modules/WM/niri
      LIBVA_DRIVER_NAME = "radeonsi";
      VDPAU_DRIVER = "radeonsi";
    };
  };

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-qt;
  };
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
  };
}
