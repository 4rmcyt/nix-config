{pkgs, ...}: {
  # Set Google API credentials for Chromium sync
  environment.sessionVariables = {
    GOOGLE_API_KEY = "REDACTED";
    GOOGLE_DEFAULT_CLIENT_ID = "839524313676-1k175brl5r4fvmi049iovjht5cqvfkvr.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "REDACTED";
  };

  # Install Chromium with Wayland/DMS optimizations
  environment.systemPackages = [
    (pkgs.chromium.override {
      enableWideVine = true;
      commandLineArgs = [
        "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks"
        "--ignore-gpu-blocklist"
        "--ozone-platform=wayland"
        "--disable-features=WaylandOverlayDelegation"
      ];
    })
  ];

  programs.chromium = {
    enable = true;

    # Extensions
    extensions = [
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "naepdomgkenhinolocfifgehidddafch" # Browserpass
      "bggfcpfjbdkhfhfmkjpbhnkhnpjjeomc" # Material Icons for GitHub
      "fkagelmloambgokoeokbpihmgpkbgbfm" # Indie Wiki Buddy
      "hlepfoohegkhhmjieoechaddaejaokhf" # Refined Github
      "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
      "olnngmhgopdgnfenhimlmnmemadhofdd" # Miniflux injector
    ];

    extraOpts = {
      # Sync settings
      "BrowserSignin" = 1;
      "SyncDisabled" = false;

      # Extension settings - Force install extensions
      "ExtensionInstallForcelist" = [
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
        "naepdomgkenhinolocfifgehidddafch" # Browserpass
        "bggfcpfjbdkhfhfmkjpbhnkhnpjjeomc" # Material Icons for GitHub
        "fkagelmloambgokoeokbpihmgpkbgbfm" # Indie Wiki Buddy
        "hlepfoohegkhhmjieoechaddaejaokhf" # Refined Github
        "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
        "olnngmhgopdgnfenhimlmnmemadhofdd" # Miniflux injector
      ];
    };
  };
}
