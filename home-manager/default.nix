{ pkgs, inputs, ... }:
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
    gpg = {
      enable = true;
      keys = [{
        source = config.sops.secrets.zeev_gpg_key.path;
        trust-ultimate = true;
      }];
    };
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
          name = "do-you-even-nix";
          file = "do-you-even-nix.zsh-theme";
          src = pkgs.fetchFromGitHub {
            owner = "miche1e";
            repo = "do-you-even-nix";
            rev = "v1.0.1";
            sha256 = "n9QYjpXlGdLx6agwp14rwcc6Jr5+0E/2h/oMuFsveHA=";
          };
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
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  home.stateVersion = "25.05";
}
