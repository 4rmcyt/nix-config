{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./extensions.nix
    ./policies.nix
    ./preferences.nix
    ./searchEngines.nix
    inputs.zen-browser.homeModules.beta
  ];

  home = {
    sessionVariables = {
      # Wayland settings
      # MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      MOZ_DISABLE_RDD_SANDBOX = "1";

      # BROWSER = lib.mkForce "zen-browser";
    };

    # Force overwrite existing files
    file = {
      ".zen/profiles.ini".force = lib.mkForce true;
      ".zen/default/search.json.mozlz4".force = lib.mkForce true;
    };
  };

  programs.zen-browser = {
    enable = true;
    package = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
    nativeMessagingHosts = [
      pkgs.browserpass
      pkgs.kdePackages.plasma-browser-integration
      pkgs.firefoxpwa
    ];
  };
}
