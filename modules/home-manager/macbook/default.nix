# File: nixos-config/modules/home-manager/macbook/default.nix
{ pkgs, ... }:
{
  home.stateVersion = "25.05";
  home.username = "vk";
  home.homeDirectory = "/Users/vk";
  # --------------------------------------------------------------------------------
  # SSH Configuration
  # --------------------------------------------------------------------------------
  # users.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAokdbrMinZjhDnVLnrXOjNn9SvzsPdlP6P3T9hAtGG8 vk@Volodymyr-Kondratenko-Mac.local"
  #   "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDc3zaVdT+TBJdjBWbN2fwSricHc7yJFGPxB9PB2sR4mkCmv6FPBd8vGZ1pYLJWEqgPU0C76IWAiSpwRrYu4Da0JKyEITh69sT+ndufTsrXJwPPxFKsUnmm2XQE0O2M2dM3wx+sMnBxWc1AMlfkWDnpP2N1Rl33ridumzEAGvJGqrn/ScpHGSgEkpZwVAnO5U8S9EjuO0h+nUJUSfLJVcl/cLeqHuF5zE8mSxsrj1FjiymZSquOEVAwNOhbCLuFVsYSEb8qujFsD7M9Umd0qvPQwCY9zN/Hb37TrNebhJ32kjIOlrWO3fnreMetIVRtTC1/cvKnGV16S32/YGiIUb2zLTfxKp2bn2qvXgLwocKf/M56fobQ6LOt60dUG1y3QwRLI1uAQggzp2N3/shQRb89nCQ/Zq67h941U2Z/RnNx7Hzl6n9DHkiKmkvXQuld0DWgh6wwG775gR2wBZHgpqtLqoRhwFVrvwIL9UkrLL4PE9A5iBEmypWsCWUomi5St+k= vk@Volodymyr-Kondratenko-Mac.local"
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks 4rmcyt@gmail.com"
  # ];
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
  home.file.".config/fontconfig/fonts.conf".source = pkgs.makeFontsConf {
    fontDirectories = with pkgs; [
      fira-code
      font-awesome
      material-design-icons
    ];
  };
  # --------------------------------------------------------------------------------
  # Program Configurations
  # --------------------------------------------------------------------------------
  programs.zsh.enable = true;
  programs.nix-index.enable = true;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
}
