{ config, pkgs, ... }:

{
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
  
  imports = [
        inputs.nix4nvchad.homeManagerModule
    ];

  home.packages = with pkgs; [
    eza
    bat
    fzf
    ripgrep
    fd
    nodejs
    python3
    gcc
    unzip
    git
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
  ];

  # Neovim with NvChad
   programs.nvchad = {
        enable = true;
        extraPackages = with pkgs; [
        nodePackages.bash-language-server
        docker-compose-language-service
        dockerfile-language-server-nodejs
        emmet-language-server
        nixd
        (python3.withPackages(ps: with ps; [
            python-lsp-server
            flake8
        ]))
        ];
        hm-activation = true;
        backup = true;
    };

  # Install NvChad
  home.activation.nvchad = ''
    if [ ! -d ~/.config/nvim ]; then
      ${pkgs.git}/bin/git clone https://github.com/NvChad/starter ~/.config/nvim
      echo "NvChad installed! Run 'nvim' to complete setup."
    fi
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "eza -l --icons";
      la = "eza -la --icons";
      ls = "eza --icons";
      cat = "bat";
      vim = "nvim";
      vi = "nvim";
      update = "sudo nixos-rebuild switch --flake /etc/nixos";
    };

    oh-my-zsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      plugins = [ "git" "dirhistory" "vi-mode" ];
    };

    initExtra = ''
      # Enable Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Source p10k config
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
    '';
  };
}