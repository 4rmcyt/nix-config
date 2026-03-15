{pkgs, ...}: {
  # Set Google API credentials for Chromium sync
  environment.sessionVariables = {
    GOOGLE_API_KEY = "REDACTED";
    GOOGLE_DEFAULT_CLIENT_ID = "839524313676-1k175brl5r4fvmi049iovjht5cqvfkvr.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "REDACTED";
  };

  # Install Chromium with Wayland/Niri/DMS optimizations
  environment.systemPackages = [
    (pkgs.chromium.override {
      enableWideVine = true;
      commandLineArgs = [
        # GPU acceleration for Nvidia
        "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
        "--ignore-gpu-blocklist"
        "--use-vulkan"

        # Wayland support
        "--ozone-platform=wayland"
        "--disable-features=WaylandOverlayDelegation"

        # HDR and Wide Color Gamut support
        "--enable-features=UseSkiaRenderer"
        "--force-color-profile=hdr10"
        "--enable-hdr"

        # Better scrolling and performance
        "--enable-smooth-scrolling"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"

        # GTK Theme support
        "--gtk-version=4"
        "--force-dark-mode"
      ];
    })
  ];

  # Chromium policies
  programs.chromium = {
    enable = true;

    extraOpts = {
      # Sync settings
      "BrowserSignin" = 1;
      "SyncDisabled" = false;

      # Always restore last session — suppresses "didn't close properly" dialog
      # caused by compositor killing Chromium with SIGTERM before it can write exit_type=Normal
      "RestoreOnStartup" = 1;

      # Secure DNS via NextDNS
      "DnsOverHttpsMode" = "secure";
      "DnsOverHttpsTemplates" = "https://dns.nextdns.io/nextdns0";

      # Allow manual extension installation
      "ExtensionInstallBlocklist" = [];
      "ExtensionInstallAllowlist" = ["*"];
    };
  };
}
