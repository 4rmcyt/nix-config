{pkgs, ...}: {
  programs.vscodium.profiles.default.extensions = with pkgs.vscode-marketplace; [
    irongeek.vscode-env
    foxundermoon.shell-format
    redhat.vscode-yaml
    tamasfe.even-better-toml
    yzhang.markdown-all-in-one
    mikestead.dotenv
    esbenp.prettier-vscode

    jnoortheen.nix-ide
    ms-python.isort
    ms-python.python
    ms-python.vscode-python-envs
    mkhl.direnv
    nefrob.vscode-just-syntax

    # DevOps
    # ms-azuretools.vscode-docker
    # ms-kubernetes-tools.vscode-kubernetes-tools
    # ms-vscode-remote.remote-containers
    # ms-vscode-remote.remote-ssh

    pkief.material-icon-theme
    qufiwefefwoyn.kanagawa

    tomoki1207.pdf
    github.vscode-github-actions

    anthropic.claude-code
    feiren200.ai-commit-craft
  ];
}
