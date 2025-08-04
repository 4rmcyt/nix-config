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

  # Nix settings
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "root" "vk" ]; # 'root' is usually needed as well
      auto-optimise-store = true;
      warn-dirty = false;
      cores = 4;
      show-trace = true;
      download-buffer-size = 1073741824; # 1 GiB
      max-jobs = 4;
    };

    # Replaced deprecated 'optimise' with 'gc'
    gc = {
      automatic = true;
      dates = "weekly";
    };
  };

  services.nix-daemon.enable = true;

  # Homebrew integration
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    # 'brewPrefix' is not a valid option and has been removed.
    taps = [
      "amar1729/formulae"
    ];
    caskArgs = {
      no_quarantine = true;
    };
    casks = [
      "alt-tab"
      "displaylink"
      "docker-desktop"
      "emclient"
      "fbreader"
      "font-hack-nerd-font"
      "google-chrome"
      "linearmouse"
      "logitech-g-hub"
      "meetingbar"
      "pycharm-ce"
      "raycast"
      "sublime-text"
      "yubico-authenticator"
    ];
    brews = [
      "browserpass"
      "curl"
      "gnutls"
      "go"
      "libgcrypt"
      "libusb"
      "p11-kit"
      "pinentry"
      "python"
      "unbound"
    ];
    masApps = { };
  };

  # System-wide packages available in the environment
  environment.systemPackages = with pkgs; [
    # Removed duplicates for 'git-crypt' and 'age-plugin-yubikey'
    age
    age-plugin-yubikey
    appcleaner
    bison
    btop
    cargo
    dbeaver-bin
    delta
    deploy-rs
    direnv
    fd
    firefox
    flex
    fzf
    fontforge
    gh
    git
    git-crypt
    gpgme
    iterm2
    jellyfin-media-player
    jetbrains-mono
    jq
    just
    lorri
    m-cli
    mas
    mc
    minipro
    neofetch
    neovim
    nix-output-monitor
    nixos-generators
    nixfmt-rfc-style
    nvd
    opentofu
    pandoc
    pass
    pcsc-tools
    pet
    pinentry-tty
    pipx
    plistwatch
    poetry
    pwgen
    pyenv
    sops
    srecord
    slack
    ssh-to-age
    tailscale
    telegram-desktop
    tenv
    the-unarchiver
    tree
    utm
    vscode
    wget
    wireguard-tools
    yq
    yubico-piv-tool
    yubikey-manager
    yubikey-personalization
    youtube-music
    zoom-us
  ];

  # Environment variables
  environment.variables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.zsh}/bin/zsh";
    SYSTEMD_EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Nixpkgs configuration
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Font configuration
  fonts.packages = with pkgs; [
    material-design-icons
    font-awesome
    fira-code
  ];

  # Programs configuration
  programs = {
    nix-index.enable = true;

    git = {
      enable = true;
      userName = "volodymyr.kondratenko@datos.live";
      userEmail = "volodymyr.kondratenko@datos.live";
      signing = {
        key = "129B4C451BE08617E579CF8A625FD6A8899D566D";
        signByDefault = true;
      };
    };

    zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      # This file must be created by the user, e.g. by running 'p10k configure'
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

    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry_mac;
      enableSSHSupport = true;
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/Users/vk/.config/nixos-config";
    };
  };

  # Security settings
  security.pam.enableSudoTouchId = true;

  # macOS specific settings
  system.defaults = {
    # Settings for specific application domains
    finder = {
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      QuitMenuItem = true;
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = true;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = true;
      ShowStatusBar = true;
    };

    screencapture = {
      location = "~/Pictures/Screenshots";
      type = "png";
    };

    desktopservices = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    SoftwareUpdate = {
      AutomaticCheckEnabled = true;
      ScheduleFrequency = 1;
      AutomaticDownload = 0;
      CriticalUpdateInstall = 1;
      AutomaticallyInstallMacOSUpdates = false;
    };

    commerce.AutoUpdate = true;

    menuExtraClock = {
      ShowAMPM = false;
      ShowDate = 1; # Always
      ShowSeconds = false;
      Show24Hour = true;
    };

    # Using domain names as keys
    "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
    "com.apple.controlcenter".BatteryShowPercentage = true;
    "com.apple.ImageCapture".disableHotPlug = true;
    "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;

    # Global domain settings
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
  };

  # Used by nix-darwin
  system.stateVersion = 25.05;
}