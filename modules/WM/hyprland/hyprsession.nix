{pkgs, ...}: {
  home.packages = [
    # hyprsession from flake input (added via overlay in flake.nix)
    pkgs.hyprsession

    # Bridge script for Zed Editor
    # Hyprsession captures "zed-editor" as the command, but the binary is "zed"
    (pkgs.writeShellScriptBin "zed-editor" ''
      exec zed "$@"
    '')
  ];

  wayland.windowManager.hyprland.settings.exec-once = [
    "hyprsession"
  ];
}
