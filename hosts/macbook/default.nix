{
  pkgs,
  lib,
  username,
  ...
}:
{

  imports = [
    ../../modules/users/vk.nix
  ];

  sops.age.keyFile = "/Users/vk/.config/sops/age/keys.txt";
  sops.defaultSopsFormat = "yaml";

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

    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  

  services.nix-daemon.enable = true;

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
    nh
    nix-output-monitor
    nvd
    plistwatch
    m-cli
  ];

  # Fix variables to environment.variables
  environment.variables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.zsh}/bin/zsh";
    SYSTEMD_EDITOR = "nvim";
    VISUAL = "nvim";
  };

  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
  programs.nix-index.enable = true;
  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";

  fonts = {
    packages = with pkgs; [
      material-design-icons
      font-awesome
      fira-code
    ];
  };

  # Fix defaults structure - needs to be under system
  system.defaults = {
    CustomUserPreferences = {
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
      "com.apple.controlcenter" = {
        BatteryShowPercentage = true;
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.finder" = {
        _FXSortFoldersFirst = true;
        FXDefaultSearchScope = "SCcf";
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = true;
        ShowRemovableMediaOnDesktop = true;
      };
      "com.apple.ImageCapture".disableHotPlug = true;
      "com.apple.screencapture" = {
        location = "~/Pictures/Screenshots";
        type = "png";
      };
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        ScheduleFrequency = 1;
        AutomaticDownload = 0;
        CriticalUpdateInstall = 1;
      };
      "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
      "com.apple.commerce".AutoUpdate = true;
    };
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      AppleTemperatureUnit = "Celsius";
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = true;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };
    SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = false;
    };
    finder = {
      _FXShowPosixPathInTitle = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    menuExtraClock = {
      ShowAMPM = false;
      ShowDate = 1; # Always
      ShowSeconds = false;
      Show24Hour = true;
    };

    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-mac;
      enableSSHSupport = true;
    };

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/Users/vk/.config/nixos-config";
    };

    programs = {
      git = {
        enable = true;
        userName = "volodymyr.kondratenko@datos.live";
        userEmail = "volodymyr.kondratenko@datos.live";
        signing.key = "129B4C451BE08617E579CF8A625FD6A8899D566D";
      };

      fzf = {
        enable = true;
        enableZshIntegration = true;
        colors = {
          fg = "#D8DEE9";
          bg = "#2E3440";
          hl = "#A3BE8C";
          "fg+" = "#D8DEE9";
          "bg+" = "#434C5E";
          "hl+" = "#A3BE8C";
          pointer = "#BF616A";
          info = "#4C566A";
          spinner = "#4C566A";
          header = "#4C566A";
          prompt = "#81A1C1";
          marker = "#EBCB8B";
        };
      };
      zsh = {
        enable = true;
        syntaxHighlighting.enable = true;
        autosuggestion.enable = true;
        enableCompletion = true;
        initContent = "source ~/.p10k.zsh";
        plugins = [
          {
            name = "powerlevel10k";
            src = pkgs.zsh-powerlevel10k;
            file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
          }
          {
            name = "zsh-history-substring-search";
            src = pkgs.zsh-history-substring-search;
            file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
          }
          {
            name = "zsh-you-should-use";
            src = pkgs.zsh-you-should-use;
            file = "share/zsh-you-should-use/zsh-you-should-use.plugin.zsh";
          }
          {
            name = "nix-zsh-completions";
            src = pkgs.nix-zsh-completions;
            file = "share/zsh/site-functions/_nix";
          }
        ];
        oh-my-zsh = {
          enable = true;
          plugins = [
            "git"
            "sudo"
            "direnv"
          ];
        };
      };

      security.pam.enableSudoTouchId = true;
    };
  };
}
