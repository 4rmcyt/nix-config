{ pkgs, inputs, ... }:

{
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";

  home.packages = with pkgs; [
    git
    nixfmt-rfc-style
    gnupg 
  ];

  imports = [
    ./dots/nvim/default.nix
  ];

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      userName = "4rmcyt";
      userEmail = "4rmcyt@gmail.com";

      signing = {
        key = "FD1AA16D16ACD8A003AD6D7AD85B52C9288A138E";
        signByDefault = true;
      };
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      initContent = "setopt autocd";

      shellAliases = {
        ll = "ls -l";
        update = "sudo nixos-rebuild switch --flake .#homeserver";
      };

      powerlevel10k = {
        enable = true;
        configFile = ./dots/zsh/.p10k.zsh;
      };

      plugins = [
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
        }
        {
          name = "zsh-completions";
          src = pkgs.zsh-completions;
        }
        {
          name = "zsh-history-substring-search";
          src = pkgs.zsh-history-substring-search;
        }
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.zsh-syntax-highlighting;
        }
        {
          name = "you-should-use";
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

    nixfmt = {
      enable = true;
      rfcStyle = true;
    };
  };

  home.stateVersion = "25.05";
}