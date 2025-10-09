{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./extensions.nix
    ./policies.nix
    ./preferences.nix
    ./searchEngines.nix
    inputs.zen-browser.homeModules.beta
  ];

  home.sessionVariables = {
    # Wayland settings
    # MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    # XDG_CURRENT_DESKTOP = "sway";
    MOZ_DISABLE_RDD_SANDBOX = "1";
    
    BROWSER = lib.mkForce "zen-browser";
  };

  programs.zen-browser = {
    enable = true;
    package = inputs.zen-browser.packages.${pkgs.system}.beta;
    nativeMessagingHosts = [
      pkgs.browserpass
      pkgs.kdePackages.plasma-browser-integration
      pkgs.firefoxpwa
    ];
  };

  # Force overwrite existing files
  home.file.".zen/profiles.ini".force = lib.mkForce true;
  home.file.".zen/default/search.json.mozlz4".force = lib.mkForce true;
}
