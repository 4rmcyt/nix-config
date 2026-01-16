{pkgs, ...}: {
  home.packages = [
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
