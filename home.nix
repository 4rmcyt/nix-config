{ config, pkgs, ... }:

{
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

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
    (nerdfonts.override { fonts = [ "Meslo" "FiraCode" "JetBrainsMono" ]; })
  ];

  # Neovim with NvChad
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nodePackages.typescript-language-server
      nodePackages.pyright
      rust-analyzer
      gopls
      
      # Formatters
      stylua
      nodePackages.prettier
      black
      rustfmt
      
      # Other tools
      tree-sitter
      ripgrep
      fd
    ];
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