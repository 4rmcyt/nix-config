{ pkgs, inputs, ... }: {
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";

  imports = [
    inputs.nix4nvchad.homeManagerModules.default
  ];

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
      # Replace the broken line with this:
      {
        name = "do-you-even-nix";
        src = pkgs.fetchFromGitHub {
          owner = "seletskiy";
          repo = "zsh-do-you-even-nix";
          rev = "985d1e605d67e716e9c6806543b5735158654ff4";
          sha256 = "1m837gq8z73nfm3kpl8zvyw6rzznzsihy0h42vnhygljw5sv3sjw";
        };
      }
    ];


    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      # This line is all you need for the theme.
      theme = "powerlevel10k/powerlevel10k";
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

