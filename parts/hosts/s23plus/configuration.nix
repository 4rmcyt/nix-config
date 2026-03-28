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
    time.timeZone = owner.timezone;
    system.stateVersion = "24.05";

    user.shell = "${pkgs.zsh}/bin/zsh";

    networking.hosts = {
  "192.168.1.165" = ["homeserver" "serv" "atuin.example.com"];
  "192.168.1.118" = ["desktop"];
  "192.168.1.132" = ["matebook"];
};

    # Nix daemon settings
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

    # Packages at nix-on-droid level (required for installPackages activation)
    environment.packages = with pkgs; [
      zsh
      git
      helix
      zellij
      atuin
      starship
      zoxide
      fzf
      yazi
      eza
      bat
      fd
      ripgrep
      direnv
      lazygit
      gh
      bottom
      carapace
      tealdeer
      ncdu
      vim
      jq
      yq-go
      curl
      wget
      tailscale
      tree
      unzip
      zip
      openssh
      rsync
      age
      # Core Unix utilities
gnugrep
gnused
gnutar
gawk
findutils
which
less
mc
uutils-coreutils
procps

# Network
traceroute
netcat-gnu
inetutils
dnsutils

# Crypto
gnupg
pinentry-tty

    ];

    environment.etcBackupExtension = ".bak";

    # Home Manager integration
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
