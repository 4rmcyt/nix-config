{ pkgs, lib, username, ... }:
{


  imports = [
    ./hardware-configuration.nix
    ../../modules/users/vk.nix
    ../../modules/darwin
  ];

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "vk"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
      cores = 4;
      show-trace = true;
      download-buffer-size = 1073741824; # 1 GiB
      max-jobs = 4;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };

    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

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
      "emclient"
      "sublime-text"
      "raycast"
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
  ];

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
}