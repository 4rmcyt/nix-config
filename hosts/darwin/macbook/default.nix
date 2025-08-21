{ pkgs, lib, ... }:
{
  system.primaryUser = "vk";
  environment.shellInit = ''
    ulimit -n 2048
  '';
  # The settings you added

  nix.settings = {
    trusted-users = [
      "root"
      "vk"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
  };
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 1w";
  };

  nix.optimise.automatic = true;

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    brewPrefix = "/opt/homebrew/bin";
    taps = [
      "amar1729/formulae"
    ];
    caskArgs = {
      no_quarantine = true;
    };
    casks = [
      "displaylink"
      "meetingbar"
      "pycharm-ce"
      "yubico-authenticator"
      "linearmouse"
      "logitech-g-hub"
      "fbreader"
      "alt-tab"
      "docker-desktop"
      "google-chrome"
      "font-hack-nerd-font"
      "sublime-text"
      "raycast"
      "thunderbird"
    ];
    brews = [
      "curl"
      "go"
      "browserpass"
      "python"
      "pinentry"
      "pinentry-mac"
      "libusb"
      "gnupg"
      "libgcrypt"
      "p11-kit"
      "gnutls"
      "unbound"
    ];
    masApps = {
    };
  };

  # The settings moved from your flake.nix
  environment.systemPackages = with pkgs; [
    mas
    fzf
    pet
    direnv
    git
    pyenv
    gh
    tenv
    delta
    jq
    yq
    pandoc
    lorri
    btop
    tree
    jetbrains-mono
    neofetch
    nixfmt-rfc-style
    opentofu
    age-plugin-yubikey
    yubikey-manager
    tailscale
    jellyfin-media-player
    dbeaver-bin
    slack
    telegram-desktop
    iterm2
    the-unarchiver
    appcleaner
    vscode
    wireguard-tools
    zoom-us
    youtube-music
    neovim
    pinentry-tty
    deploy-rs
    git-crypt
    pass
    mc
    nixos-generators
    fd
    yubico-piv-tool
    yubikey-personalization
    pcsc-tools
    git-crypt
    gpgme
    wget
    docker
    just
    cargo
    firefox
    sops
    age
    ssh-to-age
    age-plugin-yubikey
    pipx
    poetry
    bison
    flex
    fontforge
    utm
    srecord
    minipro
    pwgen
    nixos-anywhere
    treefmt
  ];
  nix.package = pkgs.nix;
  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
  programs.nix-index.enable = true;
  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";

  fonts = {
    packages = with pkgs; [
      material-design-icons
      font-awesome
      fira-code
    ];
  };

  users.users.vk = {
    name = "vk";
    home = "/Users/vk";
  };
  # ... etc
}
