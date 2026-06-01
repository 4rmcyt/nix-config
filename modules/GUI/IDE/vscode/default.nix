{pkgs, ...}: {
  imports = [
    ./extensions.nix
    ./settings.nix
    ./languages.nix
    ./ai.nix
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;
    };
  };
}
