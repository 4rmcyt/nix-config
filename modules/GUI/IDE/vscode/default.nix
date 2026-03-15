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
    mutableExtensionsDir = false; # Prevent manual extension installs (stops Copilot from being synced)

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;
      mutableSettingsFile = true;
    };
  };
}
