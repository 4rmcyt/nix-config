{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
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
  ];

  programs.chromium = {
    enable = true;
    extraOpts = {
      "ExtensionManifestV2Availability" = 2;
    };
    extensions = [
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "naepdomgkenhinolocfifgehidddafch" # Browserpass
      "bggfcpfjbdkhfhfmkjpbhnkhnpjjeomc" # Material Icons for GitHub
      "fkagelmloambgokoeokbpihmgpkbgbfm" # Indie Wiki Buddy
      "hlepfoohegkhhmjieoechaddaejaokhf" # Refined Github
      "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
    ];
  };
}
