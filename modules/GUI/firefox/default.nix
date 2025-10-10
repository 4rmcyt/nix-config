{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./extensions.nix
    ./policies.nix
    ./preferences.nix
    ./searchEngines.nix
    ./ui.nix
    inputs.betterfox-nix.homeModules.betterfox
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    XDG_CURRENT_DESKTOP = "sway";
    MOZ_DISABLE_RDD_SANDBOX = "1";
    BROWSER = lib.mkForce "firefox";
  };

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
  };
  # Force overwrite existing files
  home.file.".mozilla/firefox/profiles.ini".force = lib.mkForce true;
  home.file.".mozilla/firefox/default/search.json.mozlz4".force = lib.mkForce true;
}
