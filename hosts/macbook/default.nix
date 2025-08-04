{
  pkgs,
  lib,
  username,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
  ...
}:
{
  imports = [
    ../../modules/users/vk.nix
    ../../modules/iterm2
  ];

  sops = {
    age.keyFile = "/Users/vk/.config/sops/age/keys.txt";
    defaultSopsFormat = "yaml";
  };

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "vk" ];
      auto-optimise-store = true;
      warn-dirty = false;
      cores = lib.systems.cpuCoreCount;
      max-jobs = lib.systems.cpuCoreCount;
      show-trace = true;
      download-buffer-size = 1073741824; # 1 GiB
    };
    optimise.automatic = true;
  };

  services.nix-daemon.enable = true;

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    taps = [ "amar1729/formulae" ];
    caskArgs.no_quarantine = true;
    casks = [
      "alt-tab"
      "displaylink"
      "docker"
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
      "gnupg"
      "gnutls"
      "go"
      "libgcrypt"
      "libusb"
      "p11-kit"
      "pinentry"
      "pinentry-mac"
      "python"
      "unbound"
    ];
    masApps = { };
  };

  environment.systemPackages = with pkgs; [
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
    docker
    fd
    firefox
    flex
    fontforge
    fzf
    gh
    git
    git-crypt
    gpgme
    iterm2
    jetbrains-mono
    jellyfin-media-player
    jq
    just
    lorri
    mas
    mc
    m-cli
    minipro
    neofetch
    neovim
    nh
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
    ssh-to-age
    slack
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

  environment.variables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.zsh}/bin/zsh";
    VISUAL = "nvim";
  };

  programs.nix-index.enable = true;
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = 4;
 

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "Hack" ]; })
    material-design-icons
    font-awesome
  ];

  # --- Correctly Structured Blocks ---
  # These were previously inside 'system.defaults', which was incorrect.

  system.defaults = {
    # Settings for macOS GUI applications
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
      "com.apple.SoftwareUpdate".AutomaticallyInstallMacOSUpdates = false;
    };
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

  programs.git = {
    enable = true;
    userName = "volodymyr.kondratenko@datos.live";
    userEmail = "volodymyr.kondratenko@datos.live";
    signing.key = "129B4C451BE08617E579CF8A625FD6A8899D566D";
  };

  programs.fzf = {
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

  # I combined the two zsh blocks for clarity
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    initContent = "source ~/.p10k.zsh";
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "direnv" ];
    };
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
  };

  security.pam.enableSudoTouchId = true;
}