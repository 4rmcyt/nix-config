{
  imports = [
    ./extensions.nix
    ./policies.nix
    ./preferences.nix
    ./searchEngines.nix
    ./ui.nix
  ];

  features.browser = "firefox"; # Change if we ever stop using Firefox (unlikely)

  hm.programs.firefox = {
    enable = true;

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

  hm.home.file.".mozilla/firefox/profiles.ini".force = true;

  environment.variables.BROWSER = "firefox"; # `man` likes having this
}
