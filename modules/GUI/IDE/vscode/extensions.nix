{pkgs, ...}: {
  programs.vscodium.profiles.default.extensions = with pkgs.vscode-marketplace; [
    irongeek.vscode-env
    foxundermoon.shell-format
    redhat.vscode-yaml
    tamasfe.even-better-toml
    vscodevim.vim
    yzhang.markdown-all-in-one
    mikestead.dotenv
    visualjj.visualjj

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
    metaphore.kanagawa-vscode-color-theme

    tomoki1207.pdf
    github.vscode-github-actions

    anthropic.claude-code
    feiren200.ai-commit-craft
  ];
}
