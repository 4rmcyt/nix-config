{pkgs, ...}: {
  imports = [
    ../../modules/TUI/common
    ../../modules/TUI/zsh
    ../../modules/TUI/atuin
  ];

  home = {
    username = "zeev";
    homeDirectory = "/home/zeev";
    stateVersion = "24.11";

    packages = with pkgs; [
      # Development tools
      deadnix
      deploy-rs
      go
      just
      nix-diff
      nix-fast-build
      nix-inspect
      nixfmt-rfc-style
      nixfmt-tree
      nil
      pyenv
      rustfmt
      shfmt
      statix

      # Audio tools
      cuetools
      shntool
      flac

      # Fonts
      meslo-lgs-nf

      # Nix utilities (common tools moved to shared/dev-tools.nix)
      nix-output-monitor
      nvd

      # System & Network tools
      nextdns
      sudo
      tuptime

      # User utilities
      borgbackup
      dive
      jq
      p7zip
      pass
      trash-cli
      tree
      unar
      unzip
      yamllint
      zip
    ];
  };

  programs.zsh.enable = true;
  # Override zsh profile for pyenv
  programs.zsh.profileExtra = ''
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
  '';

  # Create nix configuration with GitHub access token from secrets
  home.activation.createNixConfig = pkgs.lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f /run/secrets/git_access_token ]; then
      $DRY_RUN_CMD mkdir -p $HOME/.config/nix
      if [ ! "$DRY_RUN" ]; then
        echo "access-tokens = github.com=$(cat /run/secrets/git_access_token)" > $HOME/.config/nix/nix.conf
      fi
    fi
  '';
}
