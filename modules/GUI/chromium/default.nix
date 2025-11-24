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
          "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo"
          "--ignore-gpu-blocklist"
          "--enable-zero-copy"
          "--enable-features=UseOzonePlatform"
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
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "cimiefiiaegbelhefglklhhakcgmhkai" # Plasma integration
      "olnngmhgopdgnfenhimlmnmemadhofdd" # Miniflux injector
    ];

    extraOpts = {
      "BrowserSignin" = 1;
      "SyncDisabled" = false;
    };
  };
}
