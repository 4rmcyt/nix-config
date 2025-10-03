{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./extensions.nix
    ./policies.nix
    ./preferences.nix
    ./searchEngines.nix
    ./ui.nix
    inputs.betterfox.modules.homeManager.betterfox
  ];

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "sway";
    MOZ_WEBRENDER = 1;
    MOZ_USE_XINPUT2 = 1;
    MOZ_DISABLE_RDD_SANDBOX = 1;
  };

  programs.firefox = {
    enable = true;
    package = inputs.firefox-nightly.packages.x86_64-linux.firefox-nightly-bin;
    nativeMessagingHosts = [ pkgs.browserpass ];

    profiles.betterfox = {
      isDefault = true;
      search = {
        force = true;
        default = "google";
      };
      settings = {
        fastfox.enable = true;
        smoothfox.enable = true;
        "sidebar.main.tools" = "aichat,syncedtabs,history,bookmarks";
      };
    };
  };

  home.file.".mozilla/firefox/profiles.ini".force = true;
  home.sessionVariables.BROWSER = "firefox";
}
