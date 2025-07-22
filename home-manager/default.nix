{ pkgs, inputs, ... }:

{
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";

  home.packages = with pkgs; [
    git
    nixfmt-rfc-style
    gnupg zsh-powerlevel10k meslo-lgs-nf
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
      syntaxHighlighting.enable = true;
      initContent = "setopt autocd";
      shellAliases = {
        ll = "ls -l";
        update = "sudo nixos-rebuild switch --flake .#homeserver";
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
        {
          name = "zsh-powerlevel10k";
          src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
          file = "powerlevel10k.zsh-theme";
        }
        {
          name = "powerlevel10k-config";
          src = "/home/zeev/src/server/dots/zsh/p10k.zsh";
          file = "p10k.zsh";
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
  };

  home.stateVersion = "25.05";
}