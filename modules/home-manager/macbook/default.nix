{
  pkgs,
  ...
}:
{
  home.stateVersion = "25.05";
  home.username = "vk";
  home.homeDirectory = "/Users/vk";
  # --------------------------------------------------------------------------------
  # SSH Configuration
  # --------------------------------------------------------------------------------
  home.file.".ssh/authorized_keys".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAokdbrMinZjhDnVLnrXOjNn9SvzsPdlP6P3T9hAtGG8 vk@Volodymyr-Kondratenko-Mac.local
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDc3zaVdT+TBJdjBWbN2fwSricHc7yJFGPxB9PB2sR4mkCmv6FPBd8vGZ1pYLJWEqgPU0C76IWAiSpwRrYu4Da0JKyEITh69sT+ndufTsrXJwPPxFKsUnmm2XQE0O2M2dM3wx+sMnBxWc1AMlfkWDnpP2N1Rl33ridumzEAGvJGqrn/ScpHGSgEkpZwVAnO5U8S9EjuO0h+nUJUSfLJVcl/cLeqHuF5zE8mSxsrj1FjiymZSquOEVAwNOhbCLuFVsYSEb8qujFsD7M9Umd0qvPQwCY9zN/Hb37TrNebhJ32kjIOlrWO3fnreMetIVRtTC1/cvKnGV16S32/YGiIUb2zLTfxKp2bn2qvXgLwocKf/M56fobQ6LOt60dUG1y3QwRLI1uAQggzp2N3/shQRb89nCQ/Zq67h941U2Z/RnNx7Hzl6n9DHkiKmkvXQuld0DWgh6wwG775gR2wBZHgpqtLqoRhwFVrvwIL9UkrLL4PE9A5iBEmypWsCWUomi5St+k= vk@Volodymyr-Kondratenko-Mac.local
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks 4rmcyt@gmail.com
  '';

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
    zsh-powerlevel10k

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

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    nix-index.enable = true;

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      options = [ "--cmd cd" ];
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--info=inline"
        "--border"
        "--exact"
      ];
    };

    gpg = {
      enable = true;
      homedir = "~/.gnupg";
    };

    gh = {
      enable = true;
      settings = {
        editor = "hx";
        git_protocol = "ssh";
      };
    };

    git = {
      enable = true;
      settings = {
        editor = "hx";
        git_protocol = "ssh";
      };
    };
    zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      initContent = ''
         autoload -Uz compinit && compinit
         [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
         if [ $(command -v fortune) ] && [ $UID != '0' ] && [[ $- == *i* ]] && [ $TERM != 'dumb' ]; then
            ### Cowsay At Login ###
            if [ $(command -v cowsay) ]; then
                fortune -a fortunes wisdom | cowsay
            else
                fortune -a fortunes wisdom
            fi
          fi

        export PATH="$HOME/.pyenv:$PATH"
        export PYENV_VIRTUALENV_DISABLE_PROMPT=1

        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
      '';
      antidote = {
        enable = true;
        plugins = [
          "getantidote/use-omz"

          "ohmyzsh/ohmyzsh path:plugins/ansible"
          "ohmyzsh/ohmyzsh path:plugins/aws"
          "ohmyzsh/ohmyzsh path:plugins/bazel"
          "ohmyzsh/ohmyzsh path:plugins/brew"
          "ohmyzsh/ohmyzsh path:plugins/command-not-found"
          "ohmyzsh/ohmyzsh path:plugins/direnv"
          "ohmyzsh/ohmyzsh path:plugins/docker"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/fzf"
          "ohmyzsh/ohmyzsh path:plugins/poetry"
          "ohmyzsh/ohmyzsh path:plugins/pyenv"
          "ohmyzsh/ohmyzsh path:plugins/python"
          "ohmyzsh/ohmyzsh path:plugins/rust"
          "ohmyzsh/ohmyzsh path:plugins/safe-paste"
          "ohmyzsh/ohmyzsh path:plugins/z"
          "ohmyzsh/ohmyzsh path:plugins/zoxide"
          "ohmyzsh/ohmyzsh path:plugins/you-should-use"
          "ohmyzsh/ohmyzsh path:plugins/sudo"
          "ohmyzsh/ohmyzsh path:plugins/zsh-autosuggestions"
          "ohmyzsh/ohmyzsh path:plugins/zsh-history-substring-search"
          "ohmyzsh/ohmyzsh path:plugins/sudo"
          "ohmyzsh/ohmyzsh path:plugins/pass"

          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-history-substring-search"
          # "zdharma-continuum/fast-syntax-highlighting"
          "Aloxaf/fzf-tab"

          "romkatv/powerlevel10k"
        ];
      };
    };
  };
  # Copy the p10k config file into your home directory
  home.file.".p10k.zsh".source = ../../dots/zsh/.p10k.zsh;
}
