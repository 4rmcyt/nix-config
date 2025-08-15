{ pkgs, nixvim, ... }:
{

  home.packages = with pkgs; [
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
    python3Full
    deploy-rs
    just
    nixfmt-rfc-style
    nixpkgs-fmt
    nil
    nix-fast-build
    shfmt
    nixfmt-tree
    nix-inspect
    nix-diff
    zsh-powerlevel10k
    helix
    # User Utils
    pass
    jq
    dive
    yamllint
    nix-index
    fzf
    ffmpeg
    trash-cli
    zip
    unar
    unzip
    p7zip
    tree
    borgbackup
    nextdns
    nh
    nix-output-monitor
    nvd

    # System & Network Tools
    tuptime
    home-manager
  ];

  programs = {
    git = {
      enable = true;
      userName = "4rmcyt";
      userEmail = "4rmcyt@gmail.com";
      signing.key = "FD1AA16D16ACD8A003AD6D7AD85B52C9288A138E";
      extraConfig = {
        commit.gpgsign = true;
        gpg.format = "ssh";
        user.signingkey = "~/.ssh/zeev";
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      colors = {
        fg = "#D8DEE9";
        bg = "#2E3440";
        hl = "#A3BE8C";
        "fg+" = "#D8DEE9";
        "bg+" = "#434C5E";
        "hl+" = "#A3BE8C";
        pointer = "#BF616A";
        info = "#4C566A";
        spinner = "#4C566A";
        header = "#4C566A";
        prompt = "#81A1C1";
        marker = "#EBCB8B";
      };
    };

    zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      initContent = "source ~/.p10k.zsh";
      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "zsh-history-substring-search";
          src = pkgs.zsh-history-substring-search;
          file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
        }
        {
          name = "zsh-you-should-use";
          src = pkgs.zsh-you-should-use;
          file = "share/zsh-you-should-use/zsh-you-should-use.plugin.zsh";
        }
        {
          name = "nix-zsh-completions";
          src = pkgs.nix-zsh-completions;
          file = "share/zsh/site-functions/_nix";
        }
      ];
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
          "direnv"
        ];
      };
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    helix = {
      enable = true;
      settings = {
        theme = "autumn_night_transparent";
        editor.cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
      };
      languages.language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
        }
      ];
    };

  };

  services = {
    ssh-agent.enable = true;
  };
  # =================================================================
  # Activation Script to Import GPG Keys (Add this section)
  # =================================================================
  # home.activation.import-gpg-keys = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   # This script runs every time you switch home-manager generations.
  #   # It checks if the key file exists before trying to import.
  #   if [ -f "$HOME/.gnupg/imported_keys.asc" ]; then
  #     echo "Importing GPG keys..."
  #     # The '$DRY_RUN_CMD' ensures this doesn't run during a dry-run.
  #     $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "$HOME/.gnupg/imported_keys.asc"
  #   fi
  # '';

  home.stateVersion = "25.05";
}
