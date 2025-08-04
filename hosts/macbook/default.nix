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

  system.primaryUser = "vk";
  environment.shellInit = ''
    ulimit -n 2048
  '';
  # System-wide Nix settings
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Merged trusted-users from both files
      trusted-users = [
        "root"
        "vk"
        "@admin"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
      cores = 4;
      show-trace = true;
      download-buffer-size = 1073741824; # 1 GiB
      max-jobs = 4;
    };
    gc = {
      automatic = true;
      interval = "weekly";
    };
  };


  system.primaryUser 

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
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    zsh.enable = true;
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.finder" = {
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
    "com.apple.screencapture" = {
      location = "~/Desktop";
      type = "png";
    };
    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
    "com.apple.Safari" = {
      # Privacy: don’t send search queries to Apple
      UniversalSearchEnabled = false;
      SuppressSearchSuggestions = true;
      # Press Tab to highlight each item on a web page
      WebKitTabToLinksPreferenceKey = true;
      ShowFullURLInSmartSearchField = true;
      # Prevent Safari from opening ‘safe’ files automatically after downloading
      AutoOpenSafeDownloads = false;
      ShowFavoritesBar = false;
      IncludeInternalDebugMenu = true;
      IncludeDevelopMenu = true;
      WebKitDeveloperExtrasEnabledPreferenceKey = true;
      WebContinuousSpellCheckingEnabled = true;
      WebAutomaticSpellingCorrectionEnabled = false;
      AutoFillFromAddressBook = false;
      AutoFillCreditCardData = false;
      AutoFillMiscellaneousForms = false;
      WarnAboutFraudulentWebsites = true;
      WebKitJavaEnabled = false;
      WebKitJavaScriptCanOpenWindowsAutomatically = false;
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks" = true;
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled" = false;
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled" = false;
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles" = false;
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically" = false;
    };
    "com.apple.mail" = {
      DisableInlineAttachmentViewing = true;
    };
    "com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = true;
      ScheduleFrequency = 1;
      AutomaticDownload = 0;
      CriticalUpdateInstall = 1;
      AutomaticallyInstallMacOSUpdates = false;
    };
    "com.apple.commerce" = {
      AutoUpdate = true;
    };
    menuExtraClock = {
      ShowAMPM = false;
      ShowDate = 1; # Always
      ShowSeconds = false;
      Show24Hour = true;
    };
    "com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false;
    };
    "com.apple.controlcenter" = {
      BatteryShowPercentage = true;
    };
    "com.apple.ImageCapture" = {
      disableHotPlug = true;
    };
    "com.apple.TimeMachine" = {
      DoNotOfferNewDisksForBackup = true;
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
  };

  system.stateVersion = 4;
}
