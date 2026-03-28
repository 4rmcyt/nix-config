# Galaxy S23+ nix-on-droid configuration.
# Deploy: nix-on-droid switch --flake .#s23plus --impure
# Note: tailscale daemon runs as Android app — CLI available via HM packages.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
in {
  configurations.nixOnDroid.s23plus.module = {pkgs, ...}: {
    # =================================================================
    # System
    # =================================================================
    time.timeZone = owner.timezone;
    system.stateVersion = "24.05";
    user.shell = "${pkgs.zsh}/bin/zsh";

    # =================================================================
    # Networking
    # =================================================================
    networking.hosts = {
      "192.168.1.165" = ["homeserver" "serv" "atuin.example.com"];
      "192.168.1.118" = ["desktop"];
      "192.168.1.132" = ["matebook"];
    };

    # =================================================================
    # Nix
    # =================================================================
    nix.extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      connect-timeout = 10
      eval-cache = true
      auto-optimise-store = true
      max-jobs = 4
      cores = 4
      min-free = 1073741824
      max-free = 3221225472
      warn-dirty = false
    '';

    nix.substituters = [
      "https://nix-on-droid.cachix.org"
      "https://4rmcyt.cachix.org"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    nix.trustedPublicKeys = [
      "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
      "4rmcyt.cachix.org-1:yHVDqXs6TDmfSOuPbl4gcfomDK9gzTmK8FabfHLi+d8="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    # =================================================================
    # Packages
    # =================================================================
    environment.packages = with pkgs; [
      # Shell & prompt
      zsh
      starship
      direnv
      carapace

      # Editors
      vim
      helix

      # Terminal multiplexer & file manager
      zellij
      yazi

      # Git
      git
      lazygit
      gh

      # Modern CLI replacements
      eza       # ls
      bat       # cat
      fd        # find
      ripgrep   # grep
      bottom    # top
      zoxide    # cd
      fzf

      # Core Unix utilities
      uutils-coreutils
      gnugrep
      gnused
      gnutar
      gawk
      findutils
      which
      less
      mc
      procps
      tree
      ncdu

      # Archives
      unzip
      zip
      rsync

      # Network
      curl
      wget
      tailscale
      openssh
      traceroute
      netcat-gnu
      inetutils
      dnsutils

      # Data processing
      jq
      yq-go

      # Crypto & secrets
      gnupg
      pinentry-tty
      age

      # Shell history
      atuin

      # Docs
      tealdeer
    ];

    environment.etcBackupExtension = ".bak";

    # =================================================================
    # Home Manager
    # =================================================================
    home-manager = {
      useGlobalPkgs = true;
      config = {
        imports = [
          ../../../home/s23plus
        ];
      };
      extraSpecialArgs = {inherit inputs;};
      backupFileExtension = "hm-backup";
    };
  };
}