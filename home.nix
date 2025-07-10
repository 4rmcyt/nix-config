{ pkgs, inputs, ... }: {
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";

  imports = [
    inputs.nix4nvchad.homeManagerModules.default
  ];

  programs.git = {
    enable = true;
    userName = "4rmcyt";
    userEmail = "redacted@example.com"; # Change this to your email

    # This is the key setting to force SSH for GitHub
    extraConfig = {
      "url.git@github.com:".insteadOf = "https://github.com/";
    };
  };  
# 1. Zsh Configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initExtra = "setopt autocd";

    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake .#homeserver";
    };

    plugins = [
      { name = "zsh-autosuggestions"; src = pkgs.zsh-autosuggestions; }
      { name = "zsh-completions"; src = pkgs.zsh-completions; }
      { name = "zsh-history-substring-search"; src = pkgs.zsh-history-substring-search; }
      { name = "zsh-syntax-highlighting"; src = pkgs.zsh-syntax-highlighting; }
      { name = "you-should-use"; src = pkgs.zsh-you-should-use; }
      { name = "do-you-even-nix"; src = pkgs.zsh-do-you-even-nix; }
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "powerlevel10k";
    };

    powerlevel10k = {
      enable = true;
      enableTransientPrompt = true;
    };
  };

  # 2. NvChad Configuration
  programs.nvchad.enable = true;

  # Optional: Custom NvChad config
  xdg.configFile."nvim/lua/custom/chadrc.lua".text = ''
    -- This is my custom chadrc
    ---@type ChadrcConfig
    local M = {}
    M.ui = {
      theme = 'onedark',
    }
    return M
  '';

  # 3. Home Manager Setup
  programs.home-manager.enable = true;
  home.stateVersion = "25.05";
}

