# ./hosts/macbook/default.nix

{
  pkgs,
  lib,
  username,
  ...
}:
{
  # Import the user definition
  imports = [
    ../../modules/users/vk.nix
  ];

  sops.age.keyFile = "/Users/vk/.config/sops/age/keys.txt";
  sops.defaultSopsFormat = "yaml";

  # System-wide Nix settings
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Merged trusted-users from both files
      trusted-users = [ "root" "vk" "@admin" ];
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
    };
  };

  services.nix-daemon.enable = true;

  # Homebrew is a system-level integration
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


  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  fonts.packages = with pkgs; [
    material-design-icons
    font-awesome
    fira-code
  ];

  programs = {
    nix-index.enable = true;

    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-mac;
      enableSSHSupport = true;
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/Users/vk/.config/nixos-config";
    };
  };

  security.pam.enableSudoTouchId = true;

  system.defaults = {
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
    "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
    "com.apple.controlcenter".BatteryShowPercentage = true;
    "com.apple.ImageCapture".disableHotPlug = true;
    "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
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

  system.stateVersion = 25.05;
}