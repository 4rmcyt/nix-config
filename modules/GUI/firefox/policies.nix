{
  programs.firefox.policies = {
    "3rdparty".extensions = {
      # uBlock Origin - Enhanced permissions
      "uBlock0@raymondhill.net" = {
        permissions = [
          "internal:privateBrowsingAllowed"
          "internal:svgContextPropertiesAllowed"
        ];
        origins = ["<all_urls>"];
      };
    };
    # BASIC POLICIES
    DontCheckDefaultBrowser = true;
    HardwareAcceleration = true;
    TranslateEnabled = true;

    # DNS
    DNSOverHTTPS = {
      Enabled = false;
      Locked = true;
    };

    # AUTOFILL & CREDENTIALS
    OfferToSaveLogins = true;
    PasswordManagerEnabled = true;

    # PRIVACY & TELEMETRY
    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableFirefoxScreenshots = true;

    # UI POLICIES
    DisplayBookmarksToolbar = "never";
    DisplayMenuBar = "never";
    PictureInPicture.Enabled = true;
    PromptForDownloadLocation = false;

    # STARTUP
    OverrideFirstRunPage = "";
    Homepage.StartPage = "previous-session";

    # USER MESSAGING
    UserMessaging = {
      UrlbarInterventions = false;
      SkipOnboarding = true;
    };

    # FIREFOX SUGGEST
    FirefoxSuggest = {
      WebSuggestions = false;
      SponsoredSuggestions = false;
      ImproveSuggest = false;
    };

    # TRACKING PROTECTION
    EnableTrackingProtection = {
      Value = true;
      Cryptomining = true;
      Fingerprinting = true;
    };

    # NEW TAB PAGE
    FirefoxHome = {
      Search = true;
      TopSites = false;
      SponsoredTopSites = false;
      Highlights = false;
      Pocket = false;
      SponsoredPocket = false;
      Snippets = false;
    };

    # PROTOCOL HANDLERS
    Handlers.schemes = {
      vscode = {
        action = "useSystemDefault";
        ask = false;
      };
      element = {
        action = "useSystemDefault";
        ask = false;
      };
    };
  };
}
