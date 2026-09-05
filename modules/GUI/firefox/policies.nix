{
  programs.firefox.policies = {
    "3rdparty".extensions = {
      "uBlock0@raymondhill.net" = {
        permissions = [
          "internal:privateBrowsingAllowed"
          "internal:svgContextPropertiesAllowed"
        ];
        origins = ["<all_urls>"];
      };
    };
    DontCheckDefaultBrowser = true;
    HardwareAcceleration = true;
    TranslateEnabled = true;

    DNSOverHTTPS = {
      Enabled = false;
      Locked = true;
    };

    OfferToSaveLogins = true;
    PasswordManagerEnabled = true;

    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableFirefoxScreenshots = true;

    DisplayBookmarksToolbar = "never";
    DisplayMenuBar = "never";
    PictureInPicture.Enabled = true;
    PromptForDownloadLocation = false;

    OverrideFirstRunPage = "";
    Homepage.StartPage = "previous-session";

    UserMessaging = {
      UrlbarInterventions = false;
      SkipOnboarding = true;
    };

    FirefoxSuggest = {
      WebSuggestions = false;
      SponsoredSuggestions = false;
      ImproveSuggest = false;
    };

    EnableTrackingProtection = {
      Value = true;
      Cryptomining = true;
      Fingerprinting = true;
    };

    FirefoxHome = {
      Search = true;
      TopSites = false;
      SponsoredTopSites = false;
      Highlights = false;
      Pocket = false;
      SponsoredPocket = false;
      Snippets = false;
    };

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
