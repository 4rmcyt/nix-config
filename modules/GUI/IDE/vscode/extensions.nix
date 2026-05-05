{ pkgs, ... }:
{
  programs.vscode.profiles.default.extensions = with pkgs.vscode-marketplace; [
    # Formatters & Editing
    codezombiech.gitignore
    christian-kohler.path-intellisense
    gruntfuggly.todo-tree
    irongeek.vscode-env
    esbenp.prettier-vscode
    foxundermoon.shell-format
    redhat.vscode-yaml
    tamasfe.even-better-toml
    vscodevim.vim
    yzhang.markdown-all-in-one
    signageos.signageos-vscode-sops
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
    tomoki1207.pdf

    # AI
    anthropic.claude-code
    feiren200.ai-commit-craft
  ];
}
