{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    git
    nixfmt-rfc-style
    gnupg
    meslo-lgs-nf
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    defaultCacheTtl = 3600;
    maxCacheTtl = 14400;
  };

  programs = {
    git = {
      enable = true;
      userName = "4rmcyt";
      userEmail = "4rmcyt@gmail.com";
      signing.key = "FD1AA16D16ACD8A003AD6D7AD85B52C9288A138E";
      signing.signCommits = true;
    };

    ssh = {
      enable = true;
      enableZshIntegration = true;
      addKeysToAgent = "yes";
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks 4rmcyt@gmail.com"
      ];
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
      enableZshIntegration = true;
      enableAutosuggestions = true;
      enableSyntaxHighlighting = true;
      histSize = 10000;
      promptInit = ''
        if [[ -r "${config.home.homeDirectory}/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
        source "${config.home.homeDirectory}/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
        fi
      '';
      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
      ];
    };

    oh-my-zsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      plugins = [
        "git"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "direnv"
      ];
    };

    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home.stateVersion = "25.05";
}