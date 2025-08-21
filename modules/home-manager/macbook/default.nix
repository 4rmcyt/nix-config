# File: nixos-config/modules/home-manager/macbook/default.nix
{ pkgs, lib, ... }:
{
  home.stateVersion = "25.05";
  home.username = "vk";
  home.homeDirectory = "/Users/vk";

  # --------------------------------------------------------------------------------
  # Home Manager Packages (User-Specific)
  # --------------------------------------------------------------------------------
  home.packages = with pkgs; [
    # Dev Tools
    age
    age-plugin-yubikey
    bison
    cargo
    dbeaver-bin
    deploy-rs
    direnv
    docker
    fd
    flex
    git
    git-crypt
    gh
    go
    gnupg
    gpgme
    just
    lorri
    neovim
    nil
    nixfmt-rfc-style
    nixos-anywhere
    nixos-generators

    nixpkgs-fmt
    opentofu
    pandoc
    pass
    pcsc-tools
    pinentry-tty
    pipx
    poetry
    pyenv
    python3Full
    sops
    ssh-to-age
    tenv
    treefmt
    utm
    vscode
    wireguard-tools
    yq

    # System & CLI Tools
    appcleaner
    btop
    curl
    delta
    fzf

    htop
    iterm2
    jq
    mas
    mc
    minipro
    neofetch
    nix-index
    pet
    pwgen
    srecord
    tailscale
    the-unarchiver
    tree
    wget
    yubico-piv-tool
    yubikey-manager
    yubikey-personalization

    # Applications
    jellyfin-media-player
    slack
    telegram-desktop
    youtube-music
    zoom-us

  ];
  # Note: 'firefox' is now managed by the system overlay

  # --------------------------------------------------------------------------------
  # Fonts
  # --------------------------------------------------------------------------------
  home.file.".config/fontconfig/fonts.conf".source = (
    pkgs.makeFontsConf {
      fontDirectories = with pkgs; [
        fira-code
        font-awesome
        material-design-icons
      ];
    }
  );
  # --------------------------------------------------------------------------------
  # Program Configurations
  # --------------------------------------------------------------------------------
  programs.zsh.enable = true;
  programs.nix-index.enable = true;

  programs.helix = {
    enable = true;
    settings = {
      theme = "heisenberg";
      editor = {
        true-color = true;
        line-number = "relative";
        mouse = false;
        cursorline = true;
        bufferline = "multiple";
        default-line-ending = "lf";
        cursor-shape.insert = "bar";
        cursor-shape.select = "underline";
        lsp.display-inlay-hints = true;
        lsp.display-messages = true;
        file-picker.hidden = false;
        file-picker.git-ignore = true;
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
}
