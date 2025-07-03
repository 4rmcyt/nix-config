{ config, pkgs, inputs, ... }:

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

  # Additional shell configuration
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
      theme = "robbyrussell";
      plugins = [ "git" "dirhistory" "vi-mode" ];
    };
  };
}