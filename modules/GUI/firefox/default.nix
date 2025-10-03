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
    betterfox = {
      profiles.default = {
        enableAllSections = false;
        settings = {
          fastfox.enable = true;
          smoothfox.enable = true;
        };
      };
    };

    nativeMessagingHosts = [ pkgs.browserpass ];
    profiles.default = {
      isDefault = true;
      search = {
        force = true;
        default = "google";
      };

      settings = {
        # Normal firefox settings that happen to be blocked with policies
        "services.sync.declinedEngines" = "";
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.enable" = true;
        # Reduce session store frequency
        "browser.sessionstore.interval" = 300000; # 5 minutes
        # Disable crash reporter disk writes
        "toolkit.crashreporter.enabled" = false;
        # Reduce various disk writes
        "browser.download.manager.retention" = 0;
        "browser.helperApps.deleteTempFileOnExit" = true;
        # Disable safebrowsing disk cache
        "browser.safebrowsing.provider.google4.dataSharingURL" = "";
        "sidebar.main.tools" = "aichat,syncedtabs,history,bookmarks";
      };
    };
  };

  home.file.".mozilla/firefox/profiles.ini".force = true;
  home.sessionVariables.BROWSER = "firefox";
}
