{pkgs, ...}: {
  imports = [
    ./extensions.nix
    ./ai.nix
    ./mcp.nix
    ./settings.nix
    ./languages.nix
  ];

  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor-fhs;
    installRemoteServer = true;
  };
}
