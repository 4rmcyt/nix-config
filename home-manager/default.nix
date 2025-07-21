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

  home.activation.import-gpg-key = pkgs.lib.hm.dag.entryAfter ["writeBoundary"] ''
    # The GPG key is imported from the path provided by sops-nix
    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import ${config.sops.secrets.zeev_gpg_key.path} &> /dev/null
  '';

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "4rmcyt";
      userEmail = "4rmcyt@gmail.com"; # Set your email
      signing = {
        key = "FD1AA16D16ACD8A003AD6D7AD85B52C9288A138E"; # Find with: gpg --list-secret-keys
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

    nixfmt = {
      enable = true;
      formatOnSave = true;
      rfcStyle = true; # Use RFC style for formatting
    };
    
  };
  home.stateVersion = "25.05";
}
