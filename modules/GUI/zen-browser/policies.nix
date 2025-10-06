{
  programs.zen-browser.policies = {
    # === AUTOFILL & CREDENTIALS ===
    AutofillAddressEnabled = true;
    AutofillCreditCardEnabled = false;
    OfferToSaveLogins = false;

    # === BASIC POLICIES ===
    DisableAppUpdate = true;
    DisableFeedbackCommands = true;
    DontCheckDefaultBrowser = true;
    HardwareAcceleration = true;
    # NoDefaultBookmarks = true;
    TranslateEnabled = true;

    # === FIREFOX HOME (NEW TAB PAGE) ===
    FirefoxHome = {
      Search = true;
      TopSites = true;
      SponsoredTopSites = false;
      Highlights = true;
      Pocket = false;
      SponsoredPocket = false;
      Snippets = false;
    };

    # === PROTOCOL HANDLERS ===
    Handlers.schemes = {
      element = {
        action = "useSystemDefault";
        ask = false;
      };
      vscode = {
        action = "useSystemDefault";
        ask = false;
      };
    };

    # === PRIVACY & TELEMETRY ===
    DisableFirefoxScreenshots = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableTelemetry = true;

    # === STARTUP & HOMEPAGE ===
    Homepage.StartPage = "previous-session";
    OverrideFirstRunPage = "";

    # === TRACKING PROTECTION ===
    EnableTrackingProtection = {
      Value = true;
      Locked = true;
      Cryptomining = true;
      Fingerprinting = true;
    };

    # === UI POLICIES ===
    PictureInPicture.Enabled = false;
    PromptForDownloadLocation = false;

    # === USER MESSAGING ===
    UserMessaging = {
      SkipOnboarding = true;
      UrlbarInterventions = false;
    };
  };
}
