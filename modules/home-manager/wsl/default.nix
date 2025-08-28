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
      # Dev tools
      direnv
      git
      gh
      just
      nixfmt-rfc-style
      nil
      shfmt
      helix
      rustfmt
      # User Utils
      jq
      nix-index
      fzf
      zip
      unzip
      tree
      zoxide
      statix
      deadnix
      # WSL-specific tools
      wslu # WSL utilities
    ];
  };

  programs = {
    git = {
      enable = true;
      userName = "zeev";
      userEmail = "zeev@example.com"; # Update with your email
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
}
