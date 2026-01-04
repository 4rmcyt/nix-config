_: {
  # Use chromium from binary cache without rebuilding.
  # Note: WideVine support is enabled by default in nixpkgs chromium since 2022.
  # The wrapper script adds runtime flags without requiring a rebuild.
  nixpkgs.config.chromium.commandLineArgs =
    "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks "
    + "--ignore-gpu-blocklist "
    + "--ozone-platform=wayland "
    + "--disable-features=WaylandOverlayDelegation";

  # Set Google API credentials for Chromium sync
  environment.sessionVariables = {
    GOOGLE_API_KEY = "REDACTED";
    GOOGLE_DEFAULT_CLIENT_ID = "839524313676-1k175brl5r4fvmi049iovjht5cqvfkvr.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "REDACTED";
  };

  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;
    extensions = [
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "naepdomgkenhinolocfifgehidddafch" # Browserpass
      "bggfcpfjbdkhfhfmkjpbhnkhnpjjeomc" # Material Icons for GitHub
      "fkagelmloambgokoeokbpihmgpkbgbfm" # Indie Wiki Buddy
      "hlepfoohegkhhmjieoechaddaejaokhf" # Refined Github
      "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin light
      "cimiefiiaegbelhefglklhhakcgmhkai" # Plasma integration
      "olnngmhgopdgnfenhimlmnmemadhofdd" # Miniflux injector
    ];

    extraOpts = {
      "BrowserSignin" = 1;
      "SyncDisabled" = false;
    };
  };
}
