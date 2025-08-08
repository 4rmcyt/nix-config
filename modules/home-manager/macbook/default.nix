{ pkgs, ... }:

{
  # Set the state version for Home Manager
  home.stateVersion = "25.05";

  # User-specific packages
  home.packages = with pkgs; [
    age
    age-plugin-yubikey
    appcleaner
    bison
    btop
    cargo
    dbeaver-bin
    delta
    deploy-rs
    fd
    firefox
    flex
    fzf
    fontforge
    gh
    git
    git-crypt
    gpgme
    iterm2
    jetbrains-mono
    jq
    just
    lorri
    m-cli
    mas
    mc
    minipro
    neofetch
    neovim
    nix-output-monitor
    nixos-generators
    nixfmt-rfc-style
    nvd
    pandoc
    pass
    pcsc-tools
    pet
    pipx
    plistwatch
    poetry
    pwgen
    pyenv
    sops
    srecord
    slack
    ssh-to-age
    tenv
    the-unarchiver
    tree
    utm
    vscode
    wget
    yq
    yubico-piv-tool
    yubikey-manager
    yubikey-personalization
    youtube-music
    zoom-us
    firefox-bin
  ];

  # User-specific environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    SYSTEMD_EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs = {
    git = {
      enable = true;
      userName = "volodymyr.kondratenko@datos.live";
      userEmail = "volodymyr.kondratenko@datos.live";
      signing.key = "129B4C451BE08617E579CF8A625FD6A8899D566D";
    };

    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      colors = {
        fg = "#D8DEE9";
        bg = "#2E3440";
        hl = "#A3BE8C";
        "fg+" = "#D8DEE9";
        "bg+" = "#434C5E";
        "hl+" = "#A3BE8C";
        pointer = "#BF616A";
        info = "#4C566A";
        spinner = "#4C566A";
        header = "#4C566A";
        prompt = "#81A1C1";
        marker = "#EBCB8B";
      };
    };

    zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      initContent = "source ~/.p10k.zsh";
      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "zsh-history-substring-search";
          src = pkgs.zsh-history-substring-search;
        }
        {
          name = "zsh-you-should-use";
          src = pkgs.zsh-you-should-use;
        }
      ];
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
        ];
      };
    };
  };
}
