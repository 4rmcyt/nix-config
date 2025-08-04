{ pkgs, lib, username, ... }:
{
  imports = [
    ../../modules/users/vk.nix
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
        "@admin"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
    };
    gc = {
      automatic = true;
      interval.Day = 7;  # Use interval for nix-darwin
      options = "--delete-older-than 10d";
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
      "docker"
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
  };

  environment.systemPackages = with pkgs; [
    mas
    fzf
    direnv
    git
    gh
    delta
    jq
    yq
    pandoc
    btop
    tree
    jetbrains-mono
    neofetch
    nixfmt-rfc-style
    age-plugin-yubikey
    yubikey-manager
    tailscale
    slack
    telegram-desktop
    the-unarchiver
    vscode
    wireguard-tools
    zoom-us
    neovim
    deploy-rs
    git-crypt
    pass
    mc
    nixos-generators
    fd
    yubico-piv-tool
    yubikey-personalization
    pcsc-tools
    gpgme
    wget
    just
    cargo
    firefox
    sops
    age
    ssh-to-age
    pipx
    poetry
    bison
    flex
    fontforge
    utm
    srecord
    minipro
    pwgen
    plistwatch
    m-cli
  ];

  environment.variables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.zsh}/bin/zsh";
    SYSTEMD_EDITOR = "nvim";
    VISUAL = "nvim";
  };

  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
  system.stateVersion = 4;  # Use 4 for nix-darwin
  nixpkgs.hostPlatform = "aarch64-darwin";

  fonts.packages = with pkgs; [
    material-design-icons
    font-awesome
    fira-code
  ];

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
      ShowDate = 1;
      ShowSeconds = false;
      Show24Hour = true;
    };
  };
  security.pam.enableSudoTouchId = true;
}