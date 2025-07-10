{ pkgs, inputs, ... }: {
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";
  home.packages = with pkgs; [
    git             # Required by NvChad's plugin manager
    zsh-powerlevel10k # The theme files for Zsh
  ];
  imports = [
    inputs.nix4nvchad.homeManagerModules.default
  ];

  # 1. Zsh Configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # 'initContent' is the new, correct option name
    initContent = "setopt autocd";

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
      # The 'do-you-even-nix' plugin has been removed as it's unavailable
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "powerlevel10k/powerlevel10k";
    };
  };

  # 2. NvChad Configuration
  programs.nvchad.enable = true;
  xdg.configFile."nvim/lua/custom/chadrc.lua".text = ''
    -- This is my custom chadrc
    ---@type ChadrcConfig
    local M = {}
    M.ui = {
      theme = 'onedark',
    }
    return M
  '';
  # 3. Git Configuration
  programs.git = {
    enable = true;
    userName = "4rmcyt";
    userEmail = "4rmcyt@gmail.com";
    	extraConfig = {
      "url.git@github.com:".insteadOf = "https://github.com/";
    };
  };

  # 4. Home Manager Setup
  programs.home-manager.enable = true;
  home.stateVersion = "25.05";
}

