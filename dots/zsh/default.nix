{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    zsh-powerlevel10k
    meslo-lgs-nf
  ];
  home.packages = with pkgs; [ grc ];
  environment.etc."powerlevel10k/p10k.zsh".source = ./p10k.zsh;


  programs = {
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

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;
      autosuggestions.enable = true;
      zsh-autoenv.enable = true;
      syntaxHighlighting.enable = true;
      histSize = 10000;
      promptInit = ''
        # this act as your ~/.zshrc but for all users (/etc/zshrc)
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source /etc/powerlevel10k/p10k.zsh

        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        # Initialization code that may require console input (password prompts, [y/n]
        # confirmations, etc.) must go above this block; everything else may go below.
        if [[ -r "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        # uncomment if you want to customize your LS_COLORS
        # https://manpages.ubuntu.com/manpages/plucky/en/man5/dir_colors.5.html
        #LS_COLORS='...'
        #export LS_COLORS
      '';
      ohMyZsh = {
         enable = true;
         theme = "powerlevel10k/powerlevel10k";
          plugins = [
	          git
            sudo
            docker
            zsh-autosuggestions
            zsh-completions
            zsh-history-substring-search
            zsh-syntax-highlighting
            you-should-use
            web-search
	          taskwarrior
	          pass
          ];
      };
    };
  };
}