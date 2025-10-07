{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./extensions.nix
    ./policies.nix
    ./preferences.nix
    inputs.zen-browser.homeModules.beta
  ];
 

  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [
      pkgs.browserpass
      pkgs.kdePackages.plasma-browser-integration
      pkgs.firefoxpwa
    ];
  };
}
