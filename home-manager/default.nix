{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    git
    nixfmt-rfc-style
    gnupg
    meslo-lgs-nf
    nix-zsh-completions
    zsh-history-substring-search
    zsh-you-should-use
    zsh-powerlevel10k
  ];

  programs = {
    git = {
      enable = true;
      userName = "4rmcyt";
      userEmail = "4rmcyt@gmail.com";
      signing.key = "FD1AA16D16ACD8A003AD6D7AD85B52C9288A138E";
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
          name = "powerlevel10k";                                                           
          src = pkgs.zsh-powerlevel10k;                                                     
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";                         
        }
      ];
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
          "nix-zsh-completions"
          "zsh-history-substring-search"
          "zsh-you-should-use"
          "direnv"
        ];
      };
    };

    
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home.stateVersion = "25.05";
}