# nixos-config/modules/home-manager/wsl/default.nix
{
  pkgs,
  lib,
  ...
}:
{
  home = {
    stateVersion = "25.05";
    username = "zeev";
    homeDirectory = "/home/zeev";
    packages = with pkgs; [
      # Shell & Editor
      zsh
      neovim
      vim
      meslo-lgs-nf
      # Dev tools
      direnv
      go
      gnupg
      git
      gh
      just
      nixfmt-rfc-style
      nil
      shfmt
      zsh-powerlevel10k
      helix
      rustfmt
      # User Utils
      jq
      yamllint
      nix-index
      fzf
      zip
      unar
      unzip
      p7zip
      tree
      zoxide
      statix
      deadnix
      # System & Network Tools
      home-manager
      # WSL-specific tools
      wslu # WSL utilities
    ];
  };

  programs = {
    git = {
      enable = true;
      userName = "zeev";
      userEmail = "zeev@example.com"; # Update with your email
      signing = {
        key = null;
        signByDefault = true;
      };
      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      
      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
        ".." = "cd ..";
        "..." = "cd ../..";
        rebuild = "sudo nixos-rebuild switch --flake .#wsl";
      };
      
      initExtra = ''
        # PowerLevel10k
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        
        # Load p10k config if it exists
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
        
        # WSL-specific configurations
        export BROWSER="wslview"
        export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
      '';
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  # Copy dotfiles
  home.file = {
    ".p10k.zsh".source = ../../dots/zsh/.p10k.zsh;
  };
}