{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./policies.nix
    ./preferences.nix
    ./searchEngines.nix
    ./ui.nix
  ];

  programs.firefox = {
    enable = true;
    package = inputs.firefox-nightly.packages.x86_64-linux.firefox-nightly-bin;

    nativeMessagingHosts = [
      pkgs.browserpass
      pkgs.firefoxpwa
    ];
    betterfox.enable = true;

    profiles.default = {
      settings = {
        "fastfox.enable" = true;
      };
      extensions = {
        packages = with inputs.firefox-addons.packages."x86_64-linux"; [
          # === AD BLOCKING & PRIVACY ===
          darkreader
          ublock-origin

          # === DEVELOPER TOOLS ===
          refined-github

          # === MEDIA & ENTERTAINMENT ===
          return-youtube-dislikes

          # === PRODUCTIVITY & NAVIGATION ===
          indie-wiki-buddy
        ];
      };
    };
  };

  home.file.".mozilla/firefox/profiles.ini".force = lib.mkForce true;
  home.file.".mozilla/firefox/default/search.json.mozlz4".force = lib.mkForce true;
}
