{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    # Shell & Editor
    zsh
    neovim
    vim
    meslo-lgs-nf
    # Dev tools
    direnv
    go
    python3Full
    deploy-rs
    just
    nixfmt-rfc-style
    nixpkgs-fmt
    nil
    git-crypt
    nix-fast-build
    shfmt
    nixfmt-tree
    nix-inspect
    nix-diff
    # User Utils
    pass
    gnupg
    jq
    mc
    age
    sops
    ssh-to-age
    openssh
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
    pinentry-tty
    # System & Network Tools
    pciutils
    wget
    curl
    gawk
    gnugrep
    iproute2
    htop
    btop
    lsof
    openssl
    powertop
    lm_sensors
    apacheHttpd
    iotop
    cachix
    tuptime
    nmap
  ];

  programs = {
    git = {
      enable = true;
      userName = "4rmcyt";
      userEmail = "4rmcyt@gmail.com";
      signing.key = "FD1AA16D16ACD8A003AD6D7AD85B52C9288A138E";
    };

    nixvim = {
      enable = true;
      colorschemes.catppuccin.enable = true;
      plugins.lualine.enable = true;
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
  };

  # =================================================================
  # Activation Script to Import GPG Keys (Add this section)
  # =================================================================

  # sops.secrets.gpg-private-key = {
  #   sopsFile = ../../../secrets/gpg/all-gpg-keys.asc.enc;
  #   path = "${config.home.homeDirectory}/.gnupg/sops_imported_key.asc";
  #   owner = config.home.username;
  #   group = config.users.primaryGroup;
  # };

  #  systemd.services.deploy-gpg = {
  #   description = "Deploy a user's PGP key";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "sops-nix.service" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = config.hostSpec.username;
  #     ExecStart = "${pkgs.writeShellScript "deploy-gpg.sh" # bash
  #       ''
  #         if [ -s ${config.sops.secrets."${sopsKeyPath}".path} ]; then
  #           mkdir -p ${gnupgphome} -m "0700"
  #           ${pkgs.gnupg}/bin/gpg --pinentry-mode loopback --import ${
  #             config.sops.secrets."${sopsKeyPath}".path
  #           }

  #           # Set passwd
  #           if [ -s ${config.sops.secrets."${sopsPasswdPath}".path} ]; then
  #             secretKeyId=${getSecretKeyIDs}
  #             for key in ''${secretKeyId[@]}
  #             do
  #               cat "${
  #                 config.sops.secrets."${sopsPasswdPath}".path
  #               }" | ${pkgs.gnupg}/bin/gpg --batch --passphrase-fd 0 --pinentry-mode loopback --edit-key $key passwd quit
  #             done
  #           fi
  #         fi
  #       ''
  #     }";
  #   };
  # };

  home.stateVersion = "25.05";
}
