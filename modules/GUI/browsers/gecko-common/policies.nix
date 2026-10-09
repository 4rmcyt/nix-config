let
  moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
in {
  ExtensionSettings = {
    "addon@darkreader.org" = {
      install_url = moz "darkreader";
      installation_mode = "force_installed";
    };

    "uBlock0@raymondhill.net" = {
      install_url = moz "ublock-origin";
      installation_mode = "force_installed";
    };

    "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = {
      install_url = moz "refined-github-";
      installation_mode = "force_installed";
    };

    "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
      install_url = moz "return-youtube-dislikes";
      installation_mode = "force_installed";
    };

    "indie-wiki-buddy@einaregilsson.com" = {
      install_url = moz "indie-wiki-buddy";
      installation_mode = "force_installed";
    };

    # komf — metadata fetcher integration for the Komga webui
    "{2c5b0916-8452-46fe-aa0b-7dc7d1e514f0}" = {
      install_url = moz "komf";
      installation_mode = "force_installed";
    };
  };

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
}
