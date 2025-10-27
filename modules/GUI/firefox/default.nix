{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    # ./extensions.nix
    ./policies.nix
    ./preferences.nix
    ./searchEngines.nix
    ./ui.nix
    inputs.betterfox-nix.homeModules.betterfox
  ];

  programs.firefox = {
    enable = true;
    package = inputs.firefox-nightly.packages.x86_64-linux.firefox-nightly-bin;
    nativeMessagingHosts = [
      pkgs.browserpass
      pkgs.kdePackages.plasma-browser-integration
      pkgs.firefoxpwa
    ];
    betterfox = {
      enable = true;
      profiles.default.settings = {
        fastfox.enable = true;
      };
    };

    extensions = with inputs.firefox-addons.packages."x86_64-linux"; [
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
  # Force overwrite existing files
  home.file.".mozilla/firefox/profiles.ini".force = lib.mkForce true;
  home.file.".mozilla/firefox/default/search.json.mozlz4".force = lib.mkForce true;
}
