{ pkgs, inputs, config,... }:
{
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";
  home.packages = with pkgs; [
    git
    nixfmt-rfc-style
  ];
  imports = [
    inputs.nix4nvchad.homeManagerModules.default
  ];

  programs = {
    home-manager.enable = true;
    zsh = {
      enable = true;
      enableCompletion = true;
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
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
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

    nvchad = {
      enable = true;
      extraPackages = with pkgs; [
        nodePackages.bash-language-server
        docker-compose-language-service
        dockerfile-language-server-nodejs
        emmet-language-server
        nixd
        (python3.withPackages (
          ps: with ps; [
            python-lsp-server
            flake8
          ]
        ))
      ];
      hm-activation = true;
      backup = true;
    };
    gpg = {
      enable = true;
      keys = [
        {
          source = config.sops.secrets.zeev_gpg_key.path;
          trust-ultimate = true;
        }
        {
          fingerprint = "FD1AA16D16ACD8A003AD6D7AD85B52C9288A138E";        
          trust = "fully"; 
        }
      ];
    };
  };
  

  home.stateVersion = "25.05";
}
