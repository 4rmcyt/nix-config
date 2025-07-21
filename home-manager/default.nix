{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";
  home.packages = with pkgs; [
    git
    nixfmt-rfc-style
  ];
  imports = [
    inputs.nix4nvchad.homeManagerModule
  ];

  programs = {
    home-manager.enable = true;
    gpg = {
      enable = true;
      keys = [
        {
          source = config.sops.secrets.zeev_gpg_key.path;
          trust-ultimate = true;
        }
      ];
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
      nvchad.enable = true;
    };
  };
  home.stateVersion = "25.05";
}
