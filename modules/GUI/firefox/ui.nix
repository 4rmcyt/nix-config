_: {
  programs.firefox.policies.Preferences."browser.uiCustomization.state" = builtins.toJSON {
    placements = {
      widget-overflow-fixed-list = [];
      toolbar-menubar = ["menubar-items"];
      PersonalToolbar = ["personal-bookmarks"];
      nav-bar = [
        "sidebar-button"
        "back-button"
        "forward-button"
        "stop-reload-button"
        "urlbar-container"
        "downloads-button"
        "addon_darkreader_org-browser-action"
        "ublock0_raymondhill_net-browser-action"
        "_a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad_-browser-action"
        "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action"
        "indie-wiki-buddy_einaregilsson_com-browser-action"
        "unified-extensions-button"
      ];
      TabsToolbar = [
        "firefox-view-button"
        "tabbrowser-tabs"
        "new-tab-button"
        "alltabs-button"
      ];
      window-controls = [
        "minimize-button"
        "restore-button"
        "close-button"
      ];
      unified-extensions-area = [];
    };
    currentVersion = 20;
    newElementCount = 3;
  };
}
