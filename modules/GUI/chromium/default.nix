{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = lib.mkBefore (
    with pkgs; [
      (chromium.override {
        enableWideVine = true;
        commandLineArgs = [
          "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo,UseOzonePlatform"
          "--ignore-gpu-blocklist"
          "--enable-zero-copy"
          "--ozone-platform=wayland"
        ];
      })
    ]
  );

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
      "ExtensionManifestV2Availability" = 2; # 2 = Enable for all extensions
    };
  };
}
