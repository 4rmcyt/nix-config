{pkgs, ...}: {
  imports = [
    ./extensions.nix
    ./settings.nix
    ./languages.nix
    ./ai.nix
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium-fhs;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;
    };
  };
}
