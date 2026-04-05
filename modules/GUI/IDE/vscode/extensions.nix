{ pkgs, ... }:
{
  programs.vscode.profiles.default.extensions =
    with pkgs.vscode-extensions;
    [
      # Formatters & Editing
      codezombiech.gitignore
      christian-kohler.path-intellisense
      gruntfuggly.todo-tree
      irongeek.vscode-env
      esbenp.prettier-vscode
      foxundermoon.shell-format
      redhat.vscode-yaml
      tamasfe.even-better-toml

      # Languages
      jnoortheen.nix-ide
      mkhl.direnv
      ms-python.isort
      ms-python.python
      ms-python.vscode-pylance
      nefrob.vscode-just-syntax

      # DevOps
      # ms-azuretools.vscode-docker
      # ms-kubernetes-tools.vscode-kubernetes-tools
      # ms-vscode-remote.remote-containers
      # ms-vscode-remote.remote-ssh

      # Theme & Icons
      pkief.material-icon-theme

      # Utilities
      # ibecker.treefmt-vscode - moved to marketplace extensions below
      tomoki1207.pdf

      # AI
      # anthropic.claude-code # 2.1.88 removed from npm, re-enable after nixpkgs updates
      saoudrizwan.claude-dev
    ]
    ++ (with pkgs.vscode-utils; [
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          publisher = "Anthropic";
          name = "claude-code";
          version = "2.1.92";
          sha256 = "sha256-L3W9LoFA6JzsPa20Md9rOJBG/siauIJeuDcE7euZxMg=";
        };
      })
    ]);
}
