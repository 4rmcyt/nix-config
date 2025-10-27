{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    # ./extensions.nix # Still commented out
    ./policies.nix
    ./preferences.nix
    ./searchEngines.nix
    ./ui.nix
    # Removed inputs.betterfox-nix.homeModules.betterfox import from here
  ];

  programs.firefox = {
    enable = true;
    package = inputs.firefox-nightly.packages.x86_64-linux.firefox-nightly-bin;

    nativeMessagingHosts = [
      pkgs.browserpass
      pkgs.kdePackages.plasma-browser-integration
      pkgs.firefoxpwa
    ];

    # Apply betterfox settings directly within the profile
    # 'betterfox.enable = true;' is usually done at the top level HM import

    profiles.default = {
      settings = {
        # Betterfox setting moved here
        "fastfox.enable" = true;

        # You would merge settings from ./preferences.nix here too, e.g.:
        # "browser.startup.page" = 1;
        # "browser.newtabpage.enabled" = true;
        # "browser.search.region" = "US";
      };

      # Search settings moved here from ./searchEngines.nix
      # search = {
      #   force = true;
      #   default = "DuckDuckGo";
      #   order = [ "DuckDuckGo" "Google" ];
      #   engines = {
      #     "Nix Packages" = { ... };
      #     "DuckDuckGo" = { ... };
      #     "Google" = { ... };
      #   };
      # };

      # Policies moved here from ./policies.nix
      # policies = {
      #   "DisableFirefoxStudies" = true;
      #   "DisableTelemetry" = true;
      #   ...
      # };

      # UI settings (userChrome.css etc.) usually handled separately via home.file as in ./ui.nix

      extensions = {
        # Added this level
        packages = with inputs.firefox-addons.packages."x86_64-linux"; # Added .packages
        
          [
            # === AD BLOCKING & PRIVACY ===
            darkreader
            ublock-origin
            ublacklist
            terms-of-service-didnt-read

            # === DEVELOPER TOOLS ===
            refined-github

            # === MEDIA & ENTERTAINMENT ===
            fastforwardteam
            return-youtube-dislikes

            # === PRODUCTIVITY & NAVIGATION ===
            indie-wiki-buddy
            linkwarden

            # === SYSTEM INTEGRATION ===
            plasma-integration
          ];
      };
    };
  };

  # These might still be needed depending on your specific setup and HM version
  home.file.".mozilla/firefox/profiles.ini".force = lib.mkForce true;
  home.file.".mozilla/firefox/default/search.json.mozlz4".force = lib.mkForce true;
}
