{pkgs, ...}: {
  programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions;
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
      anthropic.claude-code
      saoudrizwan.claude-dev
    ]
    ++ (with pkgs.vscode-utils; [
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          publisher = "BeardedBear";
          name = "beardedtheme";
          version = "10.1.0";
          sha256 = "0c0kcl08j8ii65h5mkpgssgqgshhkf49adgxd5xh1klx8qn2zjgc";
        };
      })
      # treefmt-vscode extension temporarily removed due to build issues
    ]);
}
