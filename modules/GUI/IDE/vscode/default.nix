{pkgs, ...}: {
  imports = [
    ./extensions.nix
    ./settings.nix
    ./languages.nix
    ./ai.nix
  ];

  programs.vscodium = {
    enable = true;
    package = pkgs.vscodium-fhs;

    profiles.default = {};
  };
}
