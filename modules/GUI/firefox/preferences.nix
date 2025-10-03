{
  programs.firefox.policies.Preferences = {
    # About Config & Warnings
    "browser.aboutConfig.showWarning" = false;
    "browser.warnOnQuitShortcut" = false;
    "browser.uitour.enabled" = false;

    # Content Blocking & Privacy
    "browser.send_pings" = false;
    "privacy.donottrackheader.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.userContext.enabled" = true;
    "privacy.userContext.ui.enabled" = true;

    # Data Reporting & Telemetry
    "app.normandy.enabled" = false;
    "app.shield.optoutstudies.enabled" = false;
    "browser.ping-centre.telemetry" = false;
    "browser.urlbar.eventTelemetry.enabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.server" = "";
    "toolkit.telemetry.unified" = false;

    # DOM & Web Features
    "dom.battery.enabled" = false;
    "dom.private-attribution.submission.enabled" = true;
    "dom.push.connection.enabled" = true;
    "dom.push.enabled" = true;

    # Extensions
    "extensions.abuseReport.enabled" = false;
    "extensions.autoDisableScopes" = 0;
    "extensions.formautofill.creditCards.enabled" = true;
    "extensions.pocket.enabled" = false;
    "extensions.update.enabled" = true;
    "extensions.webcompat-reporter.enabled" = false;

    # Firefox Accounts & Services
    "browser.contentblocking.report.lockwise.enabled" = true;
    "identity.fxaccounts.commands.enabled" = true;
    "identity.fxaccounts.enabled" = true;
    "identity.fxaccounts.pairing.enabled" = true;
    "identity.fxaccounts.toolbar.enabled" = true;

    # Graphics & Hardware Acceleration
    "gfx.webrender.all" = true;
    "layers.acceleration.force-enabled" = true;
    "media.av1.enabled" = true;
    "media.cdpeg.vaapi.enabled" = true;
    "media.eme.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "media.ffvpx.enabled" = false;
    "media.rdd-ffmpeg.enabled" = true;
    "media.rdd-vpx.enabled" = false;
    "widget.dmabuf.force-enabled" = true;

    # Network & Performance
    "browser.urlbar.speculativeConnect.enabled" = true;
    "network.predictor.enabled" = true;

    # New Tab Page
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

    # Tabs
    "browser.tabs.closeTabByDblclick" = true;
    "browser.tabs.dragOverThresholdPercent" = 10;
    "browser.tabs.groups.dragOverThresholdPercent" = 10;
    "browser.tabs.loadInBackground" = true;
    "browser.tabs.tabMinWidth" = 75;

    # UI & Theme
    "browser.eme.ui.enabled" = true;
    "browser.in-content.dark-mode" = true;
    "ui.systemUsesDarkTheme" = true;
    "widget.use-xdg-desktop-portal.file-picker" = 1;

    # URL Bar
    "browser.urlbar.placeholderName" = "DuckDuckGo";
    "browser.urlbar.placeholderName.private" = "DuckDuckGo";
    "browser.urlbar.shortcuts.bookmarks" = false;
    "browser.urlbar.shortcuts.history" = false;
    "browser.urlbar.shortcuts.tabs" = false;
    "browser.urlbar.suggest.calculator" = true;
    "browser.urlbar.suggest.searches" = true;
    "browser.urlbar.trimHttps" = true;
    "browser.urlbar.unitConversion.enabled" = true;
  };
}
