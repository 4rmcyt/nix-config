{
  pkgs,
  lib,
  config,
  ...
}:
# Add 'inputs' here
{
  # --------------------------------------------------------------------------------
  # System & User Configuration
  # --------------------------------------------------------------------------------
  networking.hostName = "macbook";
  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.vk = {
    name = "vk";
    home = "/Users/vk";
  };

  environment.shellInit = ''
    ulimit -n 2048
  '';
  # --------------------------------------------------------------------------------
  # Nix Configuration (System-Wide)
  # --------------------------------------------------------------------------------
  nix = {
    package = pkgs.nix;
    settings = {
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
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 1w";
    };
    optimise.automatic = true;
  };

  # --------------------------------------------------------------------------------
  # Homebrew Management (System-Wide Integration)
  # --------------------------------------------------------------------------------
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    brewPrefix = "/opt/homebrew/bin";
    taps = [ "amar1729/formulae" ];
    caskArgs = {
      no_quarantine = true;
    };
    casks = [
      "alt-tab"
      "android-commandlinetools"
      "android-platform-tools"
      "discord"
      "displaylink"
      "docker-desktop"
      "emclient"
      "fbreader"
      "firefox"
      "font-hack-nerd-font"
      "google-chrome"
      "jellyfin-media-player"
      "linearmouse"
      "logitech-g-hub"
      "meetingbar"
      "obsidian"
      "pycharm-ce"
      "raycast"
      "sublime-text"
      "thunderbird"
      "transmission-remote-gui"
      "yubico-authenticator"
    ];
    brews = [
      "adb-enhanced"
      "brotli"
      "ca-certificates"
      "coreutils"
      "emacs"
      "gettext"
      "gmp"
      "gnutls"
      "helix"
      "libassuan"
      "libevent"
      "libgcrypt"
      "libgpg-error"
      "libidn2"
      "libksba"
      "libnghttp2"
      "libssh2"
      "libtasn1"
      "libunistring"
      "libusb"
      "lz4"
      "mpdecimal"
      "nettle"
      "npth"
      "openssl@3"
      "p11-kit"
      "pcre2"
      "pinentry"
      "pinentry-mac"
      "python@3.13"
      "readline"
      "ripgrep"
      "rtmpdump"
      "shfmt"
      "sqlite"
      "statix"
      "tree-sitter"
      "unbound"
      "xz"
      "zstd"
    ];
    masApps = { };
  };

  services.cachix-agent.enable = true;
}
