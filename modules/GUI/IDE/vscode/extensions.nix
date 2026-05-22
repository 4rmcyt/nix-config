{pkgs, ...}: {
  programs.vscode.profiles.default.extensions = with pkgs.vscode-marketplace; [
    # Formatters & Editing
    irongeek.vscode-env
    foxundermoon.shell-format
    redhat.vscode-yaml
    tamasfe.even-better-toml
    vscodevim.vim
    yzhang.markdown-all-in-one
    mikestead.dotenv

    # Languages
    jnoortheen.nix-ide
    mkhl.direnv
    ms-python.isort
    nefrob.vscode-just-syntax

    # DevOps
    # ms-azuretools.vscode-docker
    # ms-kubernetes-tools.vscode-kubernetes-tools
    # ms-vscode-remote.remote-containers
    # ms-vscode-remote.remote-ssh

    # Theme & Icons
    pkief.material-icon-theme
    qufiwefefwoyn.kanagawa
    metaphore.kanagawa-vscode-color-theme

    # Utilities
    tomoki1207.pdf
    github.vscode-github-actions

    # AI
    anthropic.claude-code
    feiren200.ai-commit-craft
  ];
}
