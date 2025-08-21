# File: nixos-config/modules/home-manager/macbook/default.nix
{
  pkgs,
  config,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
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
    awscli2
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
    gnugrep
    gnumake
    darwin.cctools
    killall
    just
    lorri
    neovim

    nix-diff
    nil
    nixos-anywhere
    nixos-generators

    nixpkgs-lint
    pandoc
    openssl
    pass
    pcsc-tools
    pinentry-tty
    pipx
    poetry
    pyenv
    python3Full
    pyenv
    virtualenv
    sops
    ssh-to-age
    tenv
    treefmt
    utm
    vscode
    wireguard-tools

    yq
    tmux

    # System & CLI Tools
    appcleaner
    btop
    curl
    delta
    fzf
    write-good

    htop
    iterm2
    jq
    mas
    mc
    minipro
    neofetch
    nix-index
    nix-info
    nix-prefetch-scripts
    pet
    pwgen
    srecord
    tailscale
    the-unarchiver

    tree
    wget
    yamlfmt
    yubikey-agent
    yubikey-manager
    yubikey-personalization
    zsh-powerlevel10k
    home-manager

    # Applications
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
      homedir = "/Users/vk/.gnupg";
    };
    gh = {
      enable = true;
      settings = {
        editor = "hx";
        git_protocol = "ssh";
      };
    };
    git = {
      userName = "Volodymyr Kondratenko";
      userEmail = "4rmcyt@gmail.com";
      extraConfig = {
        github.user = "4rmcyt";
      };
    };
    zsh = {
      enable = true;
      sessionVariables = {
        EDITOR = "nvim";
        ALTERNATE_EDITOR = "${pkgs.vim}/vin/vi";
        LC_CTYPE = "en_US.UTF-8";
        LEDGER_COLOR = "true";
        LESS = "-FRSXM";
        LESSCHARSET = "utf-8";
        PAGER = "less";
      };
      profileExtra = ''
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"

        export GPG_TTY=$(tty)
        if !
        pgrep -x "gpg-agent" > /dev/null; then
            ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
        fi

        export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ];
        then
            .
        '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        [ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
        [ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

        if type brew &>/dev/null;
        then
          FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
        fi
      '';
      initContent = ''
        autoload -Uz compinit && compinit

        bindkey -v
        bindkey '^f' autosuggest-accept
        bindkey '^p' history-search-backward
        bindkey '^n' history-search-forward
        bindkey '^[w' kill-region

        bindkey '^[[A' history-substring-search-up # or '\eOA'
        bindkey '^[[B' history-substring-search-down # or '\eOB'
        HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1


        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
        zstyle ':completion:*:*:docker:*' option-stacking yes
        zstyle ':completion:*:*:docker-*:*' option-stacking yes

        [[ !
        -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        if [ $(command -v fortune) ] && [ $UID != '0' ] && [[ $- == *i* ]] && [ $TERM != 'dumb' ];
        then
            ### Cowsay At Login ###
            if [ $(command -v cowsay) ];
            then
                fortune -a fortunes wisdom |
            cowsay
            else
                fortune -a fortunes wisdom
            fi
        fi
      '';
      antidote = {
        enable = true;
        useFriendlyNames = true;
        plugins = [
          "getantidote/use-omz"

          # Oh My Zsh plugins (no duplicates)
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
          "ohmyzsh/ohmyzsh path:plugins/sudo"

          # Separate community plugins
          "zsh-users/zsh-completions"
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-history-substring-search"
          "zdharma-continuum/fast-syntax-highlighting"
          "MichaelAquilina/zsh-you-should-use"
          "Aloxaf/fzf-tab"

          "romkatv/powerlevel10k"

        ];
      };
    };
  };
}
